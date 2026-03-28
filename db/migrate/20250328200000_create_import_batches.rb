class CreateImportBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :import_batches do |t|
      t.references :originator, null: true, foreign_key: true
      t.string :filename, null: false
      t.string :file_path, null: false
      t.string :file_type, null: false
      t.string :status, null: false, default: "pending"
      t.integer :total_rows, null: false, default: 0
      t.integer :processed_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.jsonb :row_errors, null: false, default: []

      t.timestamps
    end

    add_index :import_batches, :status
  end
end
