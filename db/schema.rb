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

ActiveRecord::Schema[8.1].define(version: 2026_03_31_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "credit_operations", force: :cascade do |t|
    t.bigint "available_for_investment_cents"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.decimal "expected_return_rate", precision: 7, scale: 4
    t.bigint "funded_amount_cents", null: false
    t.date "investment_end_date"
    t.date "investment_start_date"
    t.bigint "originator_id", null: false
    t.decimal "rate", precision: 7, scale: 4, null: false
    t.bigint "receivable_id", null: false
    t.string "risk_rating"
    t.string "status", default: "draft", null: false
    t.bigint "total_invested_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_credit_operations_on_discarded_at"
    t.index ["originator_id"], name: "index_credit_operations_on_originator_id"
    t.index ["receivable_id"], name: "index_credit_operations_on_receivable_id"
  end

  create_table "exports", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "deliver_to_email"
    t.string "entity", null: false
    t.text "error_message"
    t.string "file_path"
    t.string "filename"
    t.string "range", null: false
    t.string "requested_by_email"
    t.integer "row_count"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_exports_on_created_at"
    t.index ["entity"], name: "index_exports_on_entity"
    t.index ["status"], name: "index_exports_on_status"
  end

  create_table "financial_assets", force: :cascade do |t|
    t.string "asset_type", null: false
    t.bigint "book_value_cents"
    t.datetime "created_at", null: false
    t.bigint "credit_operation_id"
    t.bigint "liquidation_value_cents"
    t.bigint "market_value_cents"
    t.bigint "originator_id"
    t.bigint "receivable_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.date "valuation_date"
    t.jsonb "valuation_metadata", default: {}, null: false
    t.bigint "value_cents", null: false
    t.index ["asset_type"], name: "index_financial_assets_on_asset_type"
    t.index ["credit_operation_id"], name: "index_financial_assets_on_credit_operation_id"
    t.index ["originator_id"], name: "index_financial_assets_on_originator_id"
    t.index ["receivable_id"], name: "index_financial_assets_on_receivable_id"
    t.index ["status"], name: "index_financial_assets_on_status"
  end

  create_table "funds", force: :cascade do |t|
    t.bigint "allocated_amount_cents", default: 0, null: false
    t.bigint "available_amount_cents"
    t.datetime "created_at", null: false
    t.string "fund_type"
    t.date "inception_date"
    t.date "maturity_date"
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.decimal "target_return_rate", precision: 7, scale: 4
    t.bigint "total_commitment_cents"
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_funds_on_status"
  end

  create_table "import_batches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "failed_rows", default: 0, null: false
    t.string "file_path", null: false
    t.string "file_type", null: false
    t.string "filename", null: false
    t.bigint "originator_id"
    t.integer "processed_rows", default: 0, null: false
    t.jsonb "row_errors", default: [], null: false
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["originator_id"], name: "index_import_batches_on_originator_id"
    t.index ["status"], name: "index_import_batches_on_status"
  end

  create_table "investment_accounts", force: :cascade do |t|
    t.string "account_number", null: false
    t.bigint "available_balance_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "invested_balance_cents", default: 0, null: false
    t.bigint "investor_id", null: false
    t.bigint "originator_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["account_number"], name: "index_investment_accounts_on_account_number", unique: true
    t.index ["investor_id"], name: "index_investment_accounts_on_investor_id"
    t.index ["originator_id"], name: "index_investment_accounts_on_originator_id"
  end

  create_table "investment_risks", force: :cascade do |t|
    t.date "assessment_date", null: false
    t.datetime "created_at", null: false
    t.bigint "credit_operation_id"
    t.bigint "impact_cents"
    t.bigint "investment_id"
    t.text "mitigation_actions"
    t.string "mitigation_status", default: "pending", null: false
    t.decimal "probability", precision: 5, scale: 2
    t.jsonb "risk_metrics", default: {}, null: false
    t.decimal "risk_score", precision: 5, scale: 2
    t.string "risk_type", null: false
    t.datetime "updated_at", null: false
    t.index ["credit_operation_id"], name: "index_investment_risks_on_credit_operation_id"
    t.index ["investment_id"], name: "index_investment_risks_on_investment_id"
  end

  create_table "investments", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.datetime "created_at", null: false
    t.bigint "credit_operation_id", null: false
    t.datetime "discarded_at"
    t.bigint "fund_id"
    t.decimal "interest_rate", precision: 7, scale: 4
    t.bigint "investment_account_id", null: false
    t.date "investment_date", null: false
    t.bigint "investor_id", null: false
    t.date "maturity_date"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["credit_operation_id"], name: "index_investments_on_credit_operation_id"
    t.index ["discarded_at"], name: "index_investments_on_discarded_at"
    t.index ["fund_id"], name: "index_investments_on_fund_id"
    t.index ["investment_account_id"], name: "index_investments_on_investment_account_id"
    t.index ["investor_id"], name: "index_investments_on_investor_id"
    t.index ["status"], name: "index_investments_on_status"
  end

  create_table "investors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "investor_type"
    t.string "legal_name", null: false
    t.string "tax_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_investors_on_discarded_at"
    t.index ["tax_id"], name: "index_investors_on_tax_id_active", unique: true, where: "(discarded_at IS NULL)"
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
    t.bigint "collateral_value_cents"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.decimal "discount_rate", precision: 7, scale: 4
    t.date "due_on", null: false
    t.bigint "originator_id", null: false
    t.string "reference_number", null: false
    t.decimal "risk_weight", precision: 5, scale: 2
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

  create_table "risk_assessments", force: :cascade do |t|
    t.date "assessment_date", null: false
    t.jsonb "assessment_details", default: {}, null: false
    t.string "assessment_type"
    t.datetime "created_at", null: false
    t.bigint "credit_operation_id"
    t.date "expiry_date"
    t.bigint "originator_id"
    t.string "rating"
    t.decimal "score", precision: 5, scale: 2
    t.string "status", default: "valid", null: false
    t.datetime "updated_at", null: false
    t.index ["credit_operation_id"], name: "index_risk_assessments_on_credit_operation_id"
    t.index ["originator_id"], name: "index_risk_assessments_on_originator_id"
    t.index ["status"], name: "index_risk_assessments_on_status"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  add_foreign_key "credit_operations", "originators"
  add_foreign_key "credit_operations", "receivables"
  add_foreign_key "financial_assets", "credit_operations"
  add_foreign_key "financial_assets", "originators"
  add_foreign_key "financial_assets", "receivables"
  add_foreign_key "import_batches", "originators"
  add_foreign_key "investment_accounts", "investors"
  add_foreign_key "investment_accounts", "originators"
  add_foreign_key "investment_risks", "credit_operations"
  add_foreign_key "investment_risks", "investments"
  add_foreign_key "investments", "credit_operations"
  add_foreign_key "investments", "funds"
  add_foreign_key "investments", "investment_accounts"
  add_foreign_key "investments", "investors"
  add_foreign_key "receivables", "originators"
  add_foreign_key "regulatory_gaps", "credit_operations"
  add_foreign_key "risk_assessments", "credit_operations"
  add_foreign_key "risk_assessments", "originators"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
