# == Schema Information
#
# Table name: addresses
#
#  id           :bigint           not null, primary key
#  currency     :string           default("USD"), not null
#  legal_entity :string           default("zion_us"), not null
#  name         :string           not null
#  namespace    :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint
#
# Indexes
#
#  index_addresses_on_account_id              (account_id)
#  index_addresses_on_namespace_name_account  (namespace,name,account_id) UNIQUE
#
class Address < ApplicationRecord
  validates :namespace, presence: true
  validates :name, presence: true
  validates :legal_entity, presence: true
  validates :currency, presence: true
  validates :namespace, uniqueness: { scope: [ :name, :account_id ] }
end
