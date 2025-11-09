# Key concepts:
# - amount is stored as INTEGER in MINOR UNITS (cents)
#   -500 = -$5.00 (debit/money leaving)
#   +500 = +$5.00 (credit/money arriving)
# - committed_at and reporting_at enable two different balance views
# - Each entry references an Address (where the money lives)

class Entry < ApplicationRecord
  belongs_to :entry_set
  belongs_to :address

  validates :amount, presence: true
  validates :committed_at, presence: true
  validates :reporting_at, presence: true

  validates :amount, numericality: { other_than: 0 }

  before_validation :copy_timestamps_from_entry_set, if: -> { entry_set.present? }

  scope :committed_before, ->(time) { where("committed_at <= ?", time) }
  scope :committed_between, ->(start_time, end_time) {
    where("committed_at >= ? AND committed_at <= ?", start_time, end_time)
  }

  # scope :committed_between, ->(start_time, end_time) { where(committed_at: start_time..end_time) }

  scope :reporting_before, ->(time) { where("reporting_at <= ?", time) }
  scope :reporting_between, ->(start_time, end_time) {
    where("reporting_at >= ? AND reporting_at <= ?", start_time, end_time)
  }

  scope :for_addresses, ->(address_ids) { where(address_id: address_ids) }
  scope :for_address, ->(address_id) { where(address_id: address_id) }

  def debit?
    amount.negative?
  end

  def credit?
    amount.positive?
  end

  def amount_in_dollars
    amount.to_d / 100
  end

  private

  # Auto-copy timestamps from parent EntrySet
  # This allows querying entries directly without joining entry_sets
  def copy_timestamps_from_entry_set
    self.committed_at ||= entry_set.committed_at
    self.reporting_at ||= entry_set.reporting_at
  end
end
