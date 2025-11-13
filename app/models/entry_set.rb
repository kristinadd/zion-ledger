# == Schema Information
#
# Table name: entry_sets
#
#  id              :bigint           not null, primary key
#  committed_at    :datetime         not null
#  description     :text
#  idempotency_key :string           not null
#  reporting_at    :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_entry_sets_on_committed_at     (committed_at)
#  index_entry_sets_on_idempotency_key  (idempotency_key) UNIQUE
#  index_entry_sets_on_reporting_at     (reporting_at)
#
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
