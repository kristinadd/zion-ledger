require "rails_helper"

RSpec.describe "API::V1::BalancesController", type: :request do
  describe "GET /api/v1/balances/available" do
    it "returns list of available balance names" do
      get "/api/v1/balances/available"

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("balances")
      expect(json_response["balances"]).to be_an(Array)
      expect(json_response["balances"]).to include("customer_facing_balance")
      expect(json_response["balances"]).to include("interest_chargeable_balance")
    end

    it "returns JSON format" do
      get "/api/v1/balances/available"

      expect(response.content_type).to include("application/json")
    end

    it "returns successful status code" do
      get "/api/v1/balances/available"

      expect(response).to have_http_status(:ok)
    end
  end
end
