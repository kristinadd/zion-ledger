module Api
  module V1
    class BalancesController < ApplicationController
      def show
        balance_name = params[:balance_name] || "customer_facing_balance"
        as_of = parse_time(params[:as_of]) || Time.current
        account_id = params[:account_id]

        unless account_id.present?
          render json: { error: "account_id is required" }, status: :bad_request
          return
        end

        result = BalanceCalculator.calculate(
          balance_name: balance_name,
          account_id: account_id.to_i,
          as_of: as_of
        )

        render json: {
          account_id: account_id.to_i,
          balance_name: balance_name,
          balance: result[:balance],
          balance_in_dollars: result[:balance_in_dollars].to_f,
          currency: result[:currency],
          as_of: result[:as_of],
          time_axis: result[:time_axis],
          description: result[:description]
        }, status: :ok

      rescue BalanceCalculator::BalanceDefinitionNotFound => e
        render json: {
          error: "Balance definition not found",
          message: e.message,
          available_balances: available_balance_names
        }, status: :not_found

      rescue BalanceCalculator::InvalidTimeAxis => e
        render json: {
          error: "Invalid time axis",
          message: e.message
        }, status: :unprocessable_entity

      rescue StandardError => e
        render json: {
          error: "Internal server error",
          message: e.message
        }, status: :internal_server_error
      end

      private

      def parse_time(time_string)
        return nil if time_string.blank?
        Time.zone.parse(time_string)
      rescue ArgumentError => e
        render json: {
          error: "Invalid time format",
          message: "Could not parse '#{time_string}' as a valid time"
        }, status: :bad_request
        nil
      end

      def available_balance_names
        config_path = Rails.root.join("config", "balance_definitions.yml")
        config = YAML.load_file(config_path)
        config["balances"]&.keys || []
      rescue StandardError
        []
      end
    end
  end
end
