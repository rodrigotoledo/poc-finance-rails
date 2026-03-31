# frozen_string_literal: true

class InvestmentsFundsRisksDomain < ActiveRecord::Migration[8.1]
  def change
    create_table :investors do |t|
      t.string :legal_name, null: false
      t.string :tax_id, null: false
      t.string :investor_type
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :investors, :discarded_at
    add_index :investors, :tax_id, unique: true, where: "(discarded_at IS NULL)", name: "index_investors_on_tax_id_active"

    create_table :funds do |t|
      t.string :name, null: false
      t.string :fund_type
      t.bigint :total_commitment_cents
      t.bigint :allocated_amount_cents, default: 0, null: false
      t.bigint :available_amount_cents
      t.date :inception_date
      t.date :maturity_date
      t.decimal :target_return_rate, precision: 7, scale: 4
      t.string :status, default: "active", null: false
      t.timestamps
    end
    add_index :funds, :status

    create_table :investment_accounts do |t|
      t.references :investor, null: false, foreign_key: true
      t.references :originator, foreign_key: true
      t.string :account_number, null: false
      t.bigint :available_balance_cents, default: 0, null: false
      t.bigint :invested_balance_cents, default: 0, null: false
      t.string :status, default: "active", null: false
      t.timestamps
    end
    add_index :investment_accounts, :account_number, unique: true

    add_column :credit_operations, :total_invested_cents, :bigint, default: 0, null: false
    add_column :credit_operations, :available_for_investment_cents, :bigint
    add_column :credit_operations, :investment_start_date, :date
    add_column :credit_operations, :investment_end_date, :date
    add_column :credit_operations, :risk_rating, :string
    add_column :credit_operations, :expected_return_rate, :decimal, precision: 7, scale: 4

    add_column :receivables, :collateral_value_cents, :bigint
    add_column :receivables, :discount_rate, :decimal, precision: 7, scale: 4
    add_column :receivables, :risk_weight, :decimal, precision: 5, scale: 2

    create_table :investments do |t|
      t.references :investor, null: false, foreign_key: true
      t.references :fund, foreign_key: true
      t.references :credit_operation, null: false, foreign_key: true
      t.references :investment_account, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.decimal :interest_rate, precision: 7, scale: 4
      t.date :investment_date, null: false
      t.date :maturity_date
      t.string :status, default: "active", null: false
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :investments, :discarded_at
    add_index :investments, :status

    create_table :financial_assets do |t|
      t.references :originator, foreign_key: true
      t.references :credit_operation, foreign_key: true
      t.references :receivable, foreign_key: true
      t.string :asset_type, null: false
      t.bigint :value_cents, null: false
      t.bigint :book_value_cents
      t.bigint :market_value_cents
      t.bigint :liquidation_value_cents
      t.jsonb :valuation_metadata, default: {}, null: false
      t.date :valuation_date
      t.string :status, default: "active", null: false
      t.timestamps
    end
    add_index :financial_assets, :asset_type
    add_index :financial_assets, :status

    create_table :investment_risks do |t|
      t.references :investment, foreign_key: true
      t.references :credit_operation, foreign_key: true
      t.string :risk_type, null: false
      t.decimal :probability, precision: 5, scale: 2
      t.bigint :impact_cents
      t.decimal :risk_score, precision: 5, scale: 2
      t.jsonb :risk_metrics, default: {}, null: false
      t.date :assessment_date, null: false
      t.string :mitigation_status, default: "pending", null: false
      t.text :mitigation_actions
      t.timestamps
    end

    create_table :risk_assessments do |t|
      t.references :credit_operation, foreign_key: true
      t.references :originator, foreign_key: true
      t.string :assessment_type
      t.decimal :score, precision: 5, scale: 2
      t.string :rating
      t.jsonb :assessment_details, default: {}, null: false
      t.date :assessment_date, null: false
      t.date :expiry_date
      t.string :status, default: "valid", null: false
      t.timestamps
    end
    add_index :risk_assessments, :status
  end
end
