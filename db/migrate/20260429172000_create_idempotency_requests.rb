# frozen_string_literal: true

class CreateIdempotencyRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :idempotency_requests do |t|
      t.string  :key,    null: false
      t.string  :method, null: false
      t.string  :path,   null: false
      t.string  :request_hash, null: false

      t.integer :response_status
      t.jsonb   :response_headers, default: {}, null: false
      t.text    :response_body
      t.datetime :completed_at

      t.timestamps
    end

    add_index :idempotency_requests, %i[key method path], unique: true, name: "index_idempotency_requests_key_method_path"
    add_index :idempotency_requests, :completed_at
  end
end

