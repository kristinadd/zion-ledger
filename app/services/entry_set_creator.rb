class EntrySetCreator
  class IdempotencyConflict < StandardError; end
  class UnbalancedEntries < StandardError; end

  Result = Struct.new(:entry_set, :created?, keyword_init: true)

  def initialize(params)
    @idempotency_key = params[:idempotency_key]
    @committed_at = params[:committed_at]
    @reporting_at = params[:reporting_at]
    @description = params[:description]
    @entries_params = params[:entries] || []
  end

  def call
    existing_entry_set = EntrySet.find_by(idempotency_key: @idempotency_key)

    if existing_entry_set
      handle_existing_entry_set(existing_entry_set)
    else
      create_new_entry_set
    end
  end

  private

  def handle_existing_entry_set(existing_entry_set)
    unless payload_matches?(existing_entry_set)
      raise IdempotencyConflict, "Idempotency key already used with different payload"
    end

    Result.new(entry_set: existing_entry_set, created?: false)
  end

  def create_new_entry_set
    validate_entries_balance!

    entry_set = nil

    ActiveRecord::Base.transaction do
      entry_set = EntrySet.create!(
        idempotency_key: @idempotency_key,
        committed_at: @committed_at,
        reporting_at: @reporting_at,
        description: @description
      )

      @entries_params.each do |entry_params|
        entry_set.entries.create!(
          amount: entry_params[:amount],
          committed_at: @committed_at,
          reporting_at: @reporting_at,
          namespace: entry_params[:namespace],
          name: entry_params[:name],
          legal_entity: entry_params[:legal_entity],
          currency: entry_params[:currency],
          account_id: entry_params[:account_id]
        )
      end
    end

    Result.new(entry_set: entry_set, created?: true)
  rescue ActiveRecord::RecordNotUnique
    # Race condition: another request created the entry set between our check and insert
    # Re-fetch and handle as existing
    existing_entry_set = EntrySet.find_by!(idempotency_key: @idempotency_key)
    handle_existing_entry_set(existing_entry_set)
  end

  def validate_entries_balance!
    # Entry set must have at least 2 entries (minimum for double-entry: debit + credit)
    if @entries_params.empty?
      raise UnbalancedEntries, "Entry set must have at least 2 entries. Received 0 entries."
    end

    if @entries_params.size < 2
      raise UnbalancedEntries, "Entry set must have at least 2 entries. Received #{@entries_params.size} entry."
    end

    # Entries must sum to zero (double-entry bookkeeping requirement)
    sum = @entries_params.sum { |e| e[:amount].to_i }

    if sum != 0
      raise UnbalancedEntries, "Entries must be balanced (sum to zero). Current sum: #{sum}"
    end
  end

  def payload_matches?(existing_entry_set)
    return false unless existing_entry_set.committed_at == Time.parse(@committed_at.to_s)
    return false unless existing_entry_set.description == @description
    return false unless entries_match?(existing_entry_set)

    true
  end

  def entries_match?(existing_entry_set)
    existing_entries = existing_entry_set.entries.order(:id)
    return false unless existing_entries.size == @entries_params.size

    sorted_existing = existing_entries.map { |e| normalize_entry(e) }.sort_by(&:to_s)
    sorted_new = @entries_params.map { |e| normalize_entry_params(e) }.sort_by(&:to_s)

    sorted_existing == sorted_new
  end

  def normalize_entry(entry)
    {
      amount: entry.amount,
      namespace: entry.namespace,
      name: entry.name,
      legal_entity: entry.legal_entity,
      currency: entry.currency,
      account_id: entry.account_id
    }
  end

  def normalize_entry_params(params)
    {
      amount: params[:amount].to_i,
      namespace: params[:namespace].to_s,
      name: params[:name].to_s,
      legal_entity: params[:legal_entity].to_s,
      currency: params[:currency].to_s,
      account_id: params[:account_id]&.to_s
    }
  end
end
