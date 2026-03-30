class CreateExports < ActiveRecord::Migration[8.1]
  def change
    create_table :exports do |t|
      t.string  :entity, null: false
      t.string  :range, null: false
      t.string  :status, null: false, default: "pending"
      t.string  :requested_by_email
      t.string  :deliver_to_email
      t.string  :filename
      t.string  :file_path
      t.integer :row_count
      t.text    :error_message

      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :exports, :status
    add_index :exports, :entity
    add_index :exports, :created_at
  end
end

