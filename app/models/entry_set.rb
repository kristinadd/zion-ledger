# == Schema Information
#
# Table name: entry_sets
#
#  id              :bigint           not null, primary key
#  committed_at    :datetime         not null
#  description     :text
#  idempotency_key :string           not null
#  reporting_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class EntrySet < ApplicationRecord
  has_many :entries, dependent: :destroy

  validates :idempotency_key, presence: true, uniqueness: true
  validates :committed_at, presence: true

  def balanced?
    entries.sum(:amount) == 0
  end
end
