class CreateEntrySets < ActiveRecord::Migration[8.1]
  def change
    create_table :entry_sets do |t|
      t.datetime :committed_at, null: false
      t.datetime :reporting_at
      t.string :idempotency_key, null: false
      t.text :description

      t.timestamps
    end
  end
end
