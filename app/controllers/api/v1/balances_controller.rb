module Api
  module V1
    class BalancesController < ApplicationController
      def available
        render json: {
          balances: BalanceCalculator.available_balances
        }, status: :ok
      end
    end
  end
end
