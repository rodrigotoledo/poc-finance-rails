# frozen_string_literal: true

class CreateRegulatoryGaps < ActiveRecord::Migration[8.1]
  def change
    create_table :regulatory_gaps do |t|
      t.string :area, null: false
      t.string :code
      t.text :description
      t.string :severity
      t.string :status, null: false, default: "open"
      t.references :credit_operation, foreign_key: true

      t.timestamps
    end
  end
end
