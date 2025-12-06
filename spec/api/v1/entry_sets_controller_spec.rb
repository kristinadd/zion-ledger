require "rails_helper"

RSpec.describe "API::V1::EntrySetsController", type: :request do
  let(:committed_at) { "2025-01-15T10:30:00Z" }
  let(:idempotency_key) { "payment-order-#{SecureRandom.uuid}" }

  let(:valid_payload) do
    {
      idempotency_key: idempotency_key,
      committed_at: committed_at,
      description: "Payment for order #12345",
      entries: [
        {
          namespace: "payments",
          name: "revenue",
          amount: 5000,
          currency: "USD",
          legal_entity: "acme_corp",
          account_id: "user-789"
        },
        {
          namespace: "payments",
          name: "accounts_receivable",
          amount: -5000,
          currency: "USD",
          legal_entity: "acme_corp",
          account_id: "user-789"
        }
      ]
    }
  end

  describe "POST /api/v1/entry_sets" do
    context "with valid balanced entries" do
      it "returns 201 Created" do
        api_post "/api/v1/entry_sets", params: valid_payload

        expect(response).to have_http_status(:created)
      end

      it "returns the created entry set with entries" do
        api_post "/api/v1/entry_sets", params: valid_payload

        json = JSON.parse(response.body)
        expect(json["idempotency_key"]).to eq(idempotency_key)
        expect(json["entries"].length).to eq(2)
        expect(json["entries"].map { |e| e["amount"] }).to contain_exactly(5000, -5000)
      end

      it "creates entry_set and entries in database" do
        expect {
          api_post "/api/v1/entry_sets", params: valid_payload
        }.to change { EntrySet.count }.by(1)
          .and change { Entry.count }.by(2)
      end
    end

    context "idempotency - same request replayed" do
      before do
        api_post "/api/v1/entry_sets", params: valid_payload
      end

      it "returns 200 OK on replay" do
        api_post "/api/v1/entry_sets", params: valid_payload

        expect(response).to have_http_status(:ok)
      end

      it "returns the original entry set" do
        original_response = JSON.parse(response.body)

        api_post "/api/v1/entry_sets", params: valid_payload
        replay_response = JSON.parse(response.body)

        expect(replay_response["id"]).to eq(original_response["id"])
      end

      it "does not create duplicate records" do
        expect {
          api_post "/api/v1/entry_sets", params: valid_payload
        }.not_to change { EntrySet.count }
      end
    end

    context "idempotency conflict - same key, different payload" do
      before do
        api_post "/api/v1/entry_sets", params: valid_payload
      end

      it "returns 409 Conflict" do
        different_payload = valid_payload.merge(
          entries: [
            { namespace: "payments", name: "revenue", amount: 9999, currency: "USD", legal_entity: "acme_corp", account_id: "user-789" },
            { namespace: "payments", name: "accounts_receivable", amount: -9999, currency: "USD", legal_entity: "acme_corp", account_id: "user-789" }
          ]
        )

        api_post "/api/v1/entry_sets", params: different_payload

        expect(response).to have_http_status(:conflict)
      end

      it "returns error details" do
        different_payload = valid_payload.merge(description: "Different description")

        api_post "/api/v1/entry_sets", params: different_payload

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("idempotency_conflict")
        expect(json["message"]).to include("different payload")
      end
    end

    context "with unbalanced entries" do
      let(:unbalanced_payload) do
        valid_payload.merge(
          entries: [
            { namespace: "payments", name: "revenue", amount: 5000, currency: "USD", legal_entity: "acme_corp", account_id: "user-789" },
            { namespace: "payments", name: "accounts_receivable", amount: -4000, currency: "USD", legal_entity: "acme_corp", account_id: "user-789" }
          ]
        )
      end

      it "returns 422 Unprocessable Entity" do
        api_post "/api/v1/entry_sets", params: unbalanced_payload

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns validation error message" do
        api_post "/api/v1/entry_sets", params: unbalanced_payload

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("validation_failed")
        expect(json["message"]).to include("balanced")
      end
    end

    context "with invalid entry data" do
      let(:invalid_payload) do
        valid_payload.merge(
          entries: [
            { namespace: "payments", name: "revenue", amount: 5000, currency: "", legal_entity: "acme_corp", account_id: "user-789" },
            { namespace: "payments", name: "accounts_receivable", amount: -5000, currency: "USD", legal_entity: "acme_corp", account_id: "user-789" }
          ]
        )
      end

      it "returns 422 Unprocessable Entity" do
        api_post "/api/v1/entry_sets", params: invalid_payload

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns validation error details" do
        api_post "/api/v1/entry_sets", params: invalid_payload

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("validation_failed")
      end
    end

    context "with missing required fields" do
      it "returns 422 when idempotency_key is missing" do
        payload_without_key = valid_payload.except(:idempotency_key)

        api_post "/api/v1/entry_sets", params: payload_without_key

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 when committed_at is missing" do
        payload_without_committed = valid_payload.except(:committed_at)

        api_post "/api/v1/entry_sets", params: payload_without_committed

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
