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

ActiveRecord::Schema[8.1].define(version: 2025_03_28_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "credit_operations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "funded_amount_cents", null: false
    t.bigint "originator_id", null: false
    t.decimal "rate", precision: 7, scale: 4, null: false
    t.bigint "receivable_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_credit_operations_on_discarded_at"
    t.index ["originator_id"], name: "index_credit_operations_on_originator_id"
    t.index ["receivable_id"], name: "index_credit_operations_on_receivable_id"
  end

  create_table "originators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "legal_name", null: false
    t.string "tax_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_originators_on_discarded_at"
    t.index ["tax_id"], name: "index_originators_on_tax_id_active", unique: true, where: "(discarded_at IS NULL)"
  end

  create_table "receivables", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.date "due_on", null: false
    t.bigint "originator_id", null: false
    t.string "reference_number", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_receivables_on_discarded_at"
    t.index ["originator_id", "reference_number"], name: "index_receivables_on_originator_ref_active", unique: true, where: "(discarded_at IS NULL)"
    t.index ["originator_id"], name: "index_receivables_on_originator_id"
  end

  create_table "regulatory_gaps", force: :cascade do |t|
    t.string "area", null: false
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "credit_operation_id"
    t.text "description"
    t.datetime "discarded_at"
    t.string "severity"
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["credit_operation_id"], name: "index_regulatory_gaps_on_credit_operation_id"
    t.index ["discarded_at"], name: "index_regulatory_gaps_on_discarded_at"
  end

  add_foreign_key "credit_operations", "originators"
  add_foreign_key "credit_operations", "receivables"
  add_foreign_key "receivables", "originators"
  add_foreign_key "regulatory_gaps", "credit_operations"
end
