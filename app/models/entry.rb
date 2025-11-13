# == Schema Information
#
# Table name: entries
#
#  id           :bigint           not null, primary key
#  amount       :bigint           not null
#  committed_at :datetime         not null
#  reporting_at :datetime         not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  address_id   :bigint           not null
#  entry_set_id :bigint           not null
#
# Indexes
#
#  index_entries_on_address_committed  (address_id,committed_at)
#  index_entries_on_address_id         (address_id)
#  index_entries_on_address_reporting  (address_id,reporting_at)
#  index_entries_on_entry_set_created  (entry_set_id,created_at)
#  index_entries_on_entry_set_id       (entry_set_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id) ON DELETE => restrict
#  fk_rails_...  (entry_set_id => entry_sets.id) ON DELETE => cascade
#
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
