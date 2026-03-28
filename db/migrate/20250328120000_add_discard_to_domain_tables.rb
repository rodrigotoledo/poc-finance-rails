# frozen_string_literal: true

class AddDiscardToDomainTables < ActiveRecord::Migration[8.1]
  def up
    %i[originators receivables credit_operations regulatory_gaps].each do |table|
      add_column table, :discarded_at, :datetime
      add_index table, :discarded_at
    end

    remove_index :originators, name: "index_originators_on_tax_id"
    add_index :originators, :tax_id, unique: true, where: "discarded_at IS NULL", name: "index_originators_on_tax_id_active"

    remove_index :receivables, name: "index_receivables_on_originator_id_and_reference_number"
    add_index :receivables, %i[originator_id reference_number],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_receivables_on_originator_ref_active"
  end

  def down
    remove_index :receivables, name: "index_receivables_on_originator_ref_active"
    add_index :receivables, %i[originator_id reference_number], unique: true,
              name: "index_receivables_on_originator_id_and_reference_number"

    remove_index :originators, name: "index_originators_on_tax_id_active"
    add_index :originators, :tax_id, unique: true, name: "index_originators_on_tax_id"

    %i[originators receivables credit_operations regulatory_gaps].each do |table|
      remove_index table, :discarded_at
      remove_column table, :discarded_at
    end
  end
end
