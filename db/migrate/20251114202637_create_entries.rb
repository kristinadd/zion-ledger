class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.bigint :entry_set_id, null: false
      t.bigint :amount, null: false
      t.datetime :committed_at, null: false
      t.datetime :reporting_at

      t.string :namespace, null: false
      t.string :name, null: false
      t.string :legal_entity, null: false
      t.string :currency, null: false
      t.string :account_id

      t.timestamps
    end

    add_foreign_key :entries, :entry_sets, on_delete: :cascade
  end
end
