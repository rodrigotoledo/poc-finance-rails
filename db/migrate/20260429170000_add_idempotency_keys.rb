# frozen_string_literal: true

class AddIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    add_idempotency_key :originators, discarded: true
    add_idempotency_key :receivables, discarded: true
    add_idempotency_key :credit_operations, discarded: true
    add_idempotency_key :regulatory_gaps, discarded: true
    add_idempotency_key :investors, discarded: true
    add_idempotency_key :investments, discarded: true

    add_idempotency_key :import_batches
    add_idempotency_key :exports
    add_idempotency_key :funds
    add_idempotency_key :investment_accounts
    add_idempotency_key :financial_assets
    add_idempotency_key :investment_risks
    add_idempotency_key :risk_assessments
  end

  private

  def add_idempotency_key(table, discarded: false)
    return if column_exists?(table, :idempotency_key)

    add_column table, :idempotency_key, :string

    index_name = "index_#{table}_on_idempotency_key"
    if discarded && column_exists?(table, :discarded_at)
      add_index table, :idempotency_key, unique: true, where: "(discarded_at IS NULL)", name: index_name
    else
      add_index table, :idempotency_key, unique: true, name: index_name
    end
  end
end

