class CreateEntrySets < ActiveRecord::Migration[8.1]
  def change
    create_table :entry_sets do |t|
      t.datetime :committed_at, null: false, index: true
      t.datetime :reporting_at, null: false, index: true
      t.string :idempotency_key, null: false, index: { unique: true }
      t.text :description

      t.timestamps
    end
  end
end
