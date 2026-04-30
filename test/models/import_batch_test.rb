# frozen_string_literal: true

# == Schema Information
#
# Table name: import_batches
#
#  id              :bigint           not null, primary key
#  failed_rows     :integer          default(0), not null
#  file_path       :string           not null
#  file_type       :string           not null
#  filename        :string           not null
#  idempotency_key :string
#  processed_rows  :integer          default(0), not null
#  row_errors      :jsonb            not null
#  status          :string           default("pending"), not null
#  total_rows      :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  originator_id   :bigint
#
# Indexes
#
#  index_import_batches_on_idempotency_key  (idempotency_key) UNIQUE
#  index_import_batches_on_originator_id    (originator_id)
#  index_import_batches_on_status           (status)
#
# Foreign Keys
#
#  fk_rails_...  (originator_id => originators.id)
#
require "test_helper"

class ImportBatchTest < ActiveSupport::TestCase
  setup do
    @originator = originators(:acme)
  end

  test "valid with required attributes" do
    batch = ImportBatch.new(
      filename: "a.csv",
      file_path: "/tmp/a.csv",
      file_type: "csv",
      status: "pending",
      originator: @originator
    )
    assert batch.valid?
  end

  test "invalid file_type" do
    batch = ImportBatch.new(
      filename: "a.csv",
      file_path: "/tmp/a.csv",
      file_type: "pdf",
      status: "pending"
    )
    assert_not batch.valid?
    assert_includes batch.errors[:file_type], "is not included in the list"
  end

  test "invalid status" do
    batch = ImportBatch.new(
      filename: "a.csv",
      file_path: "/tmp/a.csv",
      file_type: "csv",
      status: "bogus"
    )
    assert_not batch.valid?
    assert_includes batch.errors[:status], "is not included in the list"
  end

  test "record_chunk_result! increments counters and completes when total reached" do
    batch = ImportBatch.create!(
      filename: "a.csv",
      file_path: "/tmp/a.csv",
      file_type: "csv",
      status: "processing",
      total_rows: 3,
      originator: @originator
    )

    batch.record_chunk_result!(
      chunk_processed: 2,
      chunk_failed: 0,
      chunk_errors: []
    )
    batch.reload
    assert_equal 2, batch.processed_rows
    assert_equal 0, batch.failed_rows
    assert_equal "processing", batch.status

    batch.record_chunk_result!(
      chunk_processed: 0,
      chunk_failed: 1,
      chunk_errors: [ { row: 4, errors: [ "bad" ] } ]
    )
    batch.reload
    assert_equal 3, batch.processed_rows
    assert_equal 1, batch.failed_rows
    assert_equal "completed", batch.status
    assert_equal 1, batch.row_errors.size
    assert_equal 4, batch.row_errors.first["row"]
  end

  test "record_chunk_result! keeps at most 2000 row_errors" do
    batch = ImportBatch.create!(
      filename: "a.csv",
      file_path: "/tmp/a.csv",
      file_type: "csv",
      status: "processing",
      total_rows: 2_100,
      originator: @originator
    )

    errs = 1_500.times.map { |i| { row: i, errors: [ "e" ] } }
    batch.record_chunk_result!(chunk_processed: 0, chunk_failed: 1_500, chunk_errors: errs)
    batch.update_column(:total_rows, 1_500)

    batch.record_chunk_result!(
      chunk_processed: 0,
      chunk_failed: 600,
      chunk_errors: 600.times.map { |i| { row: i + 10_000, errors: [ "x" ] } }
    )
    batch.reload
    assert_equal 2_000, batch.row_errors.size
    # Oldest 100 errors dropped: first kept row index is 100 from the first chunk.
    assert_equal 100, batch.row_errors.first["row"]
  end
end
