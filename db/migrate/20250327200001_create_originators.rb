# frozen_string_literal: true

class CreateOriginators < ActiveRecord::Migration[8.1]
  def change
    create_table :originators do |t|
      t.string :legal_name, null: false
      t.string :tax_id, null: false

      t.timestamps
    end

    add_index :originators, :tax_id, unique: true
  end
end
