class Address < ApplicationRecord
  validates :namespace, presence: true
  validates :name, presence: true
  validates :legal_entity, presence: true
  validates :currency, presence: true
  validates :namespace, uniqueness: { scope: [ :name, :account_id ] }
end
