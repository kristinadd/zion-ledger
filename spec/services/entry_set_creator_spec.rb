require "rails_helper"

RSpec.describe EntrySetCreator, type: :service do
  let(:committed_at) { "2025-01-15T10:30:00Z" }
  let(:idempotency_key) { "payment-order-12345" }

  let(:valid_params) do
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

  describe "#call" do
    context "with valid balanced entries" do
      it "creates an entry set with entries" do
        result = EntrySetCreator.new(valid_params).call

        expect(result.created?).to be true
        expect(result.entry_set).to be_persisted
        expect(result.entry_set.entries.count).to eq(2)
        expect(result.entry_set.idempotency_key).to eq(idempotency_key)
      end

      it "creates entries with correct attributes" do
        result = EntrySetCreator.new(valid_params).call

        revenue_entry = result.entry_set.entries.find_by(name: "revenue")
        expect(revenue_entry.amount).to eq(5000)
        expect(revenue_entry.namespace).to eq("payments")
        expect(revenue_entry.currency).to eq("USD")
        expect(revenue_entry.legal_entity).to eq("acme_corp")
        expect(revenue_entry.account_id).to eq("user-789")
      end

      it "sets committed_at on entries from entry_set" do
        result = EntrySetCreator.new(valid_params).call

        result.entry_set.entries.each do |entry|
          expect(entry.committed_at).to eq(Time.parse(committed_at))
        end
      end
    end

    context "with unbalanced entries" do
      let(:unbalanced_params) do
        valid_params.merge(
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
              amount: -4000, # Not balanced!
              currency: "USD",
              legal_entity: "acme_corp",
              account_id: "user-789"
            }
          ]
        )
      end

      it "raises UnbalancedEntries error" do
        expect {
          EntrySetCreator.new(unbalanced_params).call
        }.to raise_error(EntrySetCreator::UnbalancedEntries, /sum to zero/)
      end

      it "does not create any records" do
        expect {
          EntrySetCreator.new(unbalanced_params).call rescue nil
        }.not_to change { EntrySet.count }
      end
    end

    context "idempotency - same key, same payload" do
      it "returns existing entry set without creating new one" do
        first_result = EntrySetCreator.new(valid_params).call
        expect(first_result.created?).to be true

        second_result = EntrySetCreator.new(valid_params).call
        expect(second_result.created?).to be false
        expect(second_result.entry_set.id).to eq(first_result.entry_set.id)
      end

      it "does not create duplicate entries" do
        EntrySetCreator.new(valid_params).call

        expect {
          EntrySetCreator.new(valid_params).call
        }.not_to change { Entry.count }
      end
    end

    context "idempotency - same key, different payload" do
      it "raises IdempotencyConflict when entries differ" do
        EntrySetCreator.new(valid_params).call

        different_entries_params = valid_params.merge(
          entries: [
            {
              namespace: "payments",
              name: "revenue",
              amount: 9999,
              currency: "USD",
              legal_entity: "acme_corp",
              account_id: "user-789"
            },
            {
              namespace: "payments",
              name: "accounts_receivable",
              amount: -9999,
              currency: "USD",
              legal_entity: "acme_corp",
              account_id: "user-789"
            }
          ]
        )

        expect {
          EntrySetCreator.new(different_entries_params).call
        }.to raise_error(EntrySetCreator::IdempotencyConflict, /different payload/)
      end

      it "raises IdempotencyConflict when description differs" do
        EntrySetCreator.new(valid_params).call

        different_description_params = valid_params.merge(description: "Different description")

        expect {
          EntrySetCreator.new(different_description_params).call
        }.to raise_error(EntrySetCreator::IdempotencyConflict, /different payload/)
      end
    end

    context "with invalid entry data" do
      let(:invalid_entry_params) do
        valid_params.merge(
          entries: [
            {
              namespace: "payments",
              name: "revenue",
              amount: 5000,
              currency: "", # Invalid - blank currency
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
        )
      end

      it "raises ActiveRecord::RecordInvalid" do
        expect {
          EntrySetCreator.new(invalid_entry_params).call
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "rolls back the transaction - no entry_set created" do
        expect {
          EntrySetCreator.new(invalid_entry_params).call rescue nil
        }.not_to change { EntrySet.count }
      end
    end

    context "with optional reporting_at" do
      it "sets reporting_at when provided" do
        params_with_reporting = valid_params.merge(reporting_at: "2025-01-20T10:30:00Z")
        result = EntrySetCreator.new(params_with_reporting).call

        expect(result.entry_set.reporting_at).to eq(Time.parse("2025-01-20T10:30:00Z"))
      end

      it "allows nil reporting_at" do
        result = EntrySetCreator.new(valid_params.except(:reporting_at)).call

        expect(result.entry_set.reporting_at).to be_nil
      end
    end

    context "database race condition" do
      it "handles concurrent inserts gracefully" do
        # Simulate race condition by manually inserting before the service runs
        EntrySet.create!(
          idempotency_key: idempotency_key,
          committed_at: committed_at,
          description: valid_params[:description]
        ).tap do |es|
          valid_params[:entries].each do |entry_params|
            es.entries.create!(
              amount: entry_params[:amount],
              committed_at: committed_at,
              namespace: entry_params[:namespace],
              name: entry_params[:name],
              legal_entity: entry_params[:legal_entity],
              currency: entry_params[:currency],
              account_id: entry_params[:account_id]
            )
          end
        end

        # Now run the service - should detect existing and return it
        result = EntrySetCreator.new(valid_params).call
        expect(result.created?).to be false
      end
    end
  end
end

