class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.bigint :entry_set_id, null: false, index: true
      t.bigint :address_id, null: false, index: true
      t.bigint :amount, null: false
      t.datetime :committed_at, null: false
      t.datetime :reporting_at, null: false

      t.timestamps

      t.index [ :address_id, :committed_at ], name: "index_entries_on_address_committed"

      t.index [ :address_id, :reporting_at ], name: "index_entries_on_address_reporting"

      t.index [ :entry_set_id, :created_at ], name: "index_entries_on_entry_set_created"
    end

    add_foreign_key :entries, :entry_sets, on_delete: :cascade
    add_foreign_key :entries, :addresses, on_delete: :restrict
  end
end
