module Api
  module V1
    class EntrySetsController < ApplicationController
      def create
        result = EntrySetCreator.new(entry_set_params).call

        status = result.created? ? :created : :ok
        render json: serialize_entry_set(result.entry_set), status: status
      rescue EntrySetCreator::IdempotencyConflict => e
        render json: {
          error: "idempotency_conflict",
          message: e.message
        }, status: :conflict
      rescue EntrySetCreator::UnbalancedEntries => e
        render json: {
          error: "validation_failed",
          message: e.message
        }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          error: "validation_failed",
          message: e.message,
          details: e.record.errors.to_hash
        }, status: :unprocessable_entity
      end

      private

      def entry_set_params
        params.permit(
          :idempotency_key,
          :committed_at,
          :reporting_at,
          :description,
          entries: [
            :namespace,
            :name,
            :amount,
            :currency,
            :legal_entity,
            :account_id
          ]
        ).to_h.deep_symbolize_keys
      end

      def serialize_entry_set(entry_set)
        {
          id: entry_set.id,
          idempotency_key: entry_set.idempotency_key,
          committed_at: entry_set.committed_at.iso8601,
          reporting_at: entry_set.reporting_at&.iso8601,
          description: entry_set.description,
          created_at: entry_set.created_at.iso8601,
          entries: entry_set.entries.map { |entry| serialize_entry(entry) }
        }
      end

      def serialize_entry(entry)
        {
          id: entry.id,
          namespace: entry.namespace,
          name: entry.name,
          amount: entry.amount,
          currency: entry.currency,
          legal_entity: entry.legal_entity,
          account_id: entry.account_id,
          committed_at: entry.committed_at.iso8601,
          reporting_at: entry.reporting_at&.iso8601
        }
      end
    end
  end
end
