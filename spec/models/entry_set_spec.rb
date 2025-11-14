require "rails_helper"

RSpec.describe EntrySet, type: :model do
  describe "creating entry set with entries" do
    it "creates an entry set with two balanced entries" do
      entry_set = create(:entry_set)
      address_customer = create(:address)
      address_merchant = create(:address, :merchant)

      debit_entry = create(:entry,
        entry_set: entry_set,
        address: address_customer,
        amount: -100,
        committed_at: Time.current
      )

      credit_entry = create(:entry,
        entry_set: entry_set,
        address: address_merchant,
        amount: 100,
        committed_at: Time.current
      )

      expect(entry_set.entries.count).to eq(2)
      expect(entry_set.entries).to include(debit_entry)
      expect(entry_set.entries).to include(credit_entry)
      expect(entry_set.balanced?).to be true
      expect(entry_set.total).to eq(0)

      expect(debit_entry.address).to eq(address_customer)
      expect(debit_entry.amount).to eq(-100)
      expect(credit_entry.address).to eq(address_merchant)
      expect(credit_entry.amount).to eq(100)
    end
  end
end
