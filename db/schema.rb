# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_09_110235) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.string "legal_entity", default: "zion_us", null: false
    t.string "name", null: false
    t.string "namespace", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_addresses_on_account_id"
    t.index ["namespace", "name", "account_id"], name: "index_addresses_on_namespace_name_account", unique: true
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.bigint "amount", null: false
    t.datetime "committed_at", null: false
    t.datetime "created_at", null: false
    t.bigint "entry_set_id", null: false
    t.datetime "reporting_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id", "committed_at"], name: "index_entries_on_address_committed"
    t.index ["address_id", "reporting_at"], name: "index_entries_on_address_reporting"
    t.index ["address_id"], name: "index_entries_on_address_id"
    t.index ["entry_set_id", "created_at"], name: "index_entries_on_entry_set_created"
    t.index ["entry_set_id"], name: "index_entries_on_entry_set_id"
  end

  create_table "entry_sets", force: :cascade do |t|
    t.datetime "committed_at", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "idempotency_key", null: false
    t.datetime "reporting_at", null: false
    t.datetime "updated_at", null: false
    t.index ["committed_at"], name: "index_entry_sets_on_committed_at"
    t.index ["idempotency_key"], name: "index_entry_sets_on_idempotency_key", unique: true
    t.index ["reporting_at"], name: "index_entry_sets_on_reporting_at"
  end

  add_foreign_key "entries", "addresses", on_delete: :restrict
  add_foreign_key "entries", "entry_sets", on_delete: :cascade
end
