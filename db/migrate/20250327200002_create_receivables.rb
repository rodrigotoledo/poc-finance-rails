# frozen_string_literal: true

class CreateReceivables < ActiveRecord::Migration[8.1]
  def change
    create_table :receivables do |t|
      t.references :originator, null: false, foreign_key: true
      t.string :reference_number, null: false
      t.bigint :amount_cents, null: false
      t.date :due_on, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :receivables, %i[originator_id reference_number], unique: true
  end
end
