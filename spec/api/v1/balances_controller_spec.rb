require "rails_helper"

RSpec.describe "API::V1::BalancesController", type: :request do
  describe "GET /api/v1/balances/available" do
    it "returns a list of available balance names" do
      get "/api/v1/balances/available"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("balances")
      expect(json_response["balances"]).to match_array([
        "customer_facing_balance",
        "interest_chargeable_balance"
      ])
    end
  end
end
