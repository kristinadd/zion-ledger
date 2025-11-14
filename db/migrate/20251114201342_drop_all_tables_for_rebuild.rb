class DropAllTablesForRebuild < ActiveRecord::Migration[8.1]
  def up
    # Drop tables in order to respect foreign key constraints
    # Drop entries first (has foreign keys to addresses and entry_sets)
    drop_table :entries, if_exists: true, force: :cascade

    # Drop addresses (referenced by entries)
    drop_table :addresses, if_exists: true, force: :cascade

    # Drop entry_sets (referenced by entries)
    drop_table :entry_sets, if_exists: true, force: :cascade
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
