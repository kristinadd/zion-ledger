# EntrySet represents a complete double-entry transaction in the ledger.
#
# Each EntrySet contains multiple Entry records that must sum to zero
# (the fundamental rule of double-entry bookkeeping).
#
# Example: Coffee purchase for $5.00
#   EntrySet {
#     idempotency_key: "coffee_20241109_001",
#     description: "Coffee at Starbucks",
#     committed_at: 2024-11-09 09:00:00,
#     reporting_at: 2024-11-11 12:00:00,
#     entries: [
#       Entry { address: checking_account, amount: -500 },  # -$5.00
#       Entry { address: merchant_settlement, amount: 500 }  # +$5.00
#     ]
#   }
#   Sum: -500 + 500 = 0 ✅

class EntrySet < ApplicationRecord
  has_many :entries, dependent: :destroy

  validates :idempotency_key, presence: true, uniqueness: true
  validates :committed_at, presence: true
  validates :reporting_at, presence: true

  validate :entries_must_balance_to_zero, if: -> { entries.any? }

  # Scopes for querying by time axis (M's way)
  scope :committed_before, ->(time) { where("committed_at <= ?", time) }
  scope :committed_after, ->(time) { where("committed_at >= ?", time) }
  scope :reporting_before, ->(time) { where("reporting_at <= ?", time) }
  scope :reporting_after, ->(time) { where("reporting_at >= ?", time) }

  # Class method for idempotent creation
  # Prevents duplicate transactions if the same idempotency_key is used
  def self.create_with_idempotency!(idempotency_key:, **attributes)
    # First, try to find existing transaction
    existing = find_by(idempotency_key: idempotency_key)
    return existing if existing

    create!(idempotency_key: idempotency_key, **attributes)
  rescue ActiveRecord::RecordNotUnique
    # Race condition: another thread created it between find_by and create
    # Retry the find
    find_by!(idempotency_key: idempotency_key)
  end

  def total
    entries.sum(:amount)
  end

  def balanced?
    total == 0
  end

  private

  # Validation: Ensure double-entry rule is satisfied
  # The sum of all entries must equal zero
  # Optimization: Cache total to avoid querying database twice
  def entries_must_balance_to_zero
    current_total = total  # Query database once and store result

    unless current_total.zero?
      errors.add(:base, "Entries must sum to zero (double-entry rule). Current sum: #{current_total}")
    end
  end
end
