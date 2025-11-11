# API V1 Entries Controller
# Handles creation of ledger transactions (EntrySets with Entries)
#
# POST /v1/entries - Create a new transaction with idempotency key
#
# Request format:
# {
#   "idempotency_key": "unique_key_123",
#   "description": "Coffee purchase",
#   "committed_at": "2024-11-09T10:00:00Z",
#   "reporting_at": "2024-11-11T12:00:00Z",
#   "entries": [
#     { "address_id": 1, "amount": -500 },
#     { "address_id": 2, "amount": 500 }
#   ]
# }

module Api
  module V1
    class EntriesController < ApplicationController
      # POST /v1/entries
      def create
        # Use idempotent creation from EntrySet model
        entry_set = EntrySet.create_with_idempotency!(
          idempotency_key: entry_params[:idempotency_key],
          description: entry_params[:description],
          committed_at: parse_time(entry_params[:committed_at]),
          reporting_at: parse_time(entry_params[:reporting_at]),
          metadata: entry_params[:metadata] || {}
        )

        # Create entries for this entry set
        entries_attributes = entry_params[:entries] || []
        entries_attributes.each do |entry_attrs|
          entry_set.entries.create!(
            address_id: entry_attrs[:address_id],
            amount: entry_attrs[:amount]
          )
        end

        # Validate that entries balance to zero
        unless entry_set.valid?
          render json: {
            error: "Invalid entry set",
            details: entry_set.errors.full_messages
          }, status: :unprocessable_entity
          return
        end

        # Return created entry set with all entries
        render json: {
          id: entry_set.id,
          idempotency_key: entry_set.idempotency_key,
          description: entry_set.description,
          committed_at: entry_set.committed_at,
          reporting_at: entry_set.reporting_at,
          total: entry_set.total,
          balanced: entry_set.balanced?,
          entries: entry_set.entries.map { |e|
            {
              id: e.id,
              address_id: e.address_id,
              amount: e.amount,
              amount_in_dollars: e.amount_in_dollars.to_f
            }
          }
        }, status: :created

      rescue ActiveRecord::RecordInvalid => e
        render json: {
          error: "Validation failed",
          details: e.message
        }, status: :unprocessable_entity

      rescue StandardError => e
        render json: {
          error: "Internal server error",
          message: e.message
        }, status: :internal_server_error
      end

      private

      def entry_params
        params.require(:entry_set).permit(
          :idempotency_key,
          :description,
          :committed_at,
          :reporting_at,
          metadata: {},
          entries: [ :address_id, :amount ]
        )
      end

      def parse_time(time_string)
        return Time.current if time_string.blank?
        Time.zone.parse(time_string)
      rescue ArgumentError
        Time.current
      end
    end
  end
end
