# == Schema Information
#
# Table name: entries
#
#  id           :bigint           not null, primary key
#  entry_set_id :bigint           not null
#  amount       :bigint           not null
#  committed_at :datetime         not null
#  reporting_at :datetime
#  namespace    :string           not null
#  name         :string           not null
#  legal_entity :string           not null
#  currency     :string           not null
#  account_id   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (entry_set_id => entry_sets.id) ON DELETE => cascade
#
class Entry < ApplicationRecord
  belongs_to :entry_set

  validates :amount, presence: true
  validates :committed_at, presence: true
  validates :namespace, presence: true
  validates :name, presence: true
  validates :legal_entity, presence: true
  validates :currency, presence: true
  validates :amount, numericality: { other_than: 0 }
end
