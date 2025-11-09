class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      # The namespace - groups related addresses together
      # Example: "com.zion.account" for customer accounts
      #          "com.zion.fees" for fee collection addresses
      t.string :namespace, null: false

      # The name - identifies the type within the namespace
      # Example: "checking", "savings", "settlement"
      t.string :name, null: false

      # The legal entity - which company entity owns this
      # Example: "zion_us" if you expand to multiple countries
      t.string :legal_entity, null: false, default: "zion_us"

      # The currency - what currency this address holds
      # Example: "USD", "GBP", "EUR"
      t.string :currency, null: false, default: "USD"

      # The account_id - links to a specific customer account
      # This is nullable because not all addresses belong to customers
      # Example: Fee collection addresses don't have an account_id
      t.bigint :account_id

      # Timestamps - track when addresses are created
      t.timestamps

      # Indexes for fast lookups
      # We'll often query "give me all addresses for this account"
      t.index :account_id

      # We'll also query "give me the address for this namespace:name:account combination"
      # Unique constraint ensures one account can't have two "checking" addresses
      t.index [ :namespace, :name, :account_id ], unique: true, name: "index_addresses_on_namespace_name_account"
    end
  end
end
