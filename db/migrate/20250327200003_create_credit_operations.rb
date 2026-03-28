# frozen_string_literal: true

class CreateCreditOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_operations do |t|
      t.references :receivable, null: false, foreign_key: true
      t.references :originator, null: false, foreign_key: true
      t.bigint :funded_amount_cents, null: false
      t.decimal :rate, precision: 7, scale: 4, null: false
      t.string :status, null: false, default: "draft"

      t.timestamps
    end
  end
end
