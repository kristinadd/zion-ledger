class AddUniqueIndexToEntrySetIdempotencyKey < ActiveRecord::Migration[8.1]
  def change
    add_index :entry_sets, :idempotency_key, unique: true
  end
end
