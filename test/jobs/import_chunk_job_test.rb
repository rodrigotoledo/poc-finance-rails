# frozen_string_literal: true

require "test_helper"

class ImportChunkJobTest < ActiveJob::TestCase
  include ApiFixtures

  setup do
    @originator = originators(:acme)
    @batch = ImportBatch.create!(
      filename: "chunk.csv",
      file_path: "/tmp/chunk.csv",
      file_type: "csv",
      status: "processing",
      total_rows: 1,
      originator: @originator
    )
  end

  test "creates receivables for valid rows using batch originator" do
    ref = "REF-CHUNK-#{SecureRandom.hex(4)}"
    rows = [
      {
        "reference_number" => ref,
        "amount" => "150.00",
        "due_on" => "2030-04-01",
        "status" => "pending"
      }
    ]

    assert_difference("Receivable.count", 1) do
      ImportChunkJob.perform_now(@batch.id, rows, 0)
    end

    r = Receivable.find_by(reference_number: ref)
    assert_equal @originator, r.originator
    assert_equal 15_000, r.amount_cents

    @batch.reload
    assert_equal 1, @batch.processed_rows
    assert_equal 0, @batch.failed_rows
    assert_equal "completed", @batch.status
  end

  test "uses originator_tax_id from row when present" do
    other = create_originator!(legal_name: "Other", tax_id: unique_tax_id)
    ref = "REF-CHUNK-#{SecureRandom.hex(4)}"
    rows = [
      {
        "originator_tax_id" => other.tax_id,
        "reference_number" => ref,
        "amount" => "10.00",
        "due_on" => "2030-05-01",
        "status" => "pending"
      }
    ]

    ImportChunkJob.perform_now(@batch.id, rows, 0)

    assert_equal other, Receivable.find_by!(reference_number: ref).originator
  end

  test "counts validation failures and records row numbers" do
    @batch.update!(total_rows: 2)
    ref = "REF-CHUNK-#{SecureRandom.hex(4)}"
    rows = [
      {
        "reference_number" => ref,
        "amount" => "150.00",
        "due_on" => "2030-04-01",
        "status" => "pending"
      },
      {
        "reference_number" => "",
        "amount" => "1.00",
        "due_on" => "2030-04-01",
        "status" => "pending"
      }
    ]

    assert_difference("Receivable.count", 1) do
      ImportChunkJob.perform_now(@batch.id, rows, 0)
    end

    @batch.reload
    assert_equal 2, @batch.processed_rows
    assert_equal 1, @batch.failed_rows
    failed = @batch.row_errors.find { |e| e["row"] == 3 }
    assert failed
    assert failed["errors"].present?
  end

  test "chunk_index shifts row numbers for second chunk" do
    ref = "REF-CHUNK-#{SecureRandom.hex(4)}"
    rows = [
      {
        "reference_number" => ref,
        "amount" => "1.00",
        "due_on" => "2030-04-01",
        "status" => "invalid_status"
      }
    ]

    ImportChunkJob.perform_now(@batch.id, rows, 1)

    @batch.reload
    err = @batch.row_errors.first
    assert_equal 1002, err["row"]
  end

  test "missing amount yields nil cents and fails validation" do
    ref = "REF-CHUNK-#{SecureRandom.hex(4)}"
    rows = [
      {
        "reference_number" => ref,
        "due_on" => "2030-04-01",
        "status" => "pending"
      }
    ]

    assert_no_difference("Receivable.count") do
      ImportChunkJob.perform_now(@batch.id, rows, 0)
    end

    @batch.reload
    assert_equal 1, @batch.failed_rows
  end

  test "unparseable amount hits parse_amount_cents rescue" do
    ref = "REF-CHUNK-#{SecureRandom.hex(4)}"
    rows = [
      {
        "reference_number" => ref,
        "amount" => "%%%",
        "due_on" => "2030-04-01",
        "status" => "pending"
      }
    ]

    assert_no_difference("Receivable.count") do
      ImportChunkJob.perform_now(@batch.id, rows, 0)
    end

    @batch.reload
    assert_equal 1, @batch.failed_rows
  end

  test "unexpected error in process_row is captured as failure" do
    Receivable.expects(:new).raises(StandardError.new("simulated failure"))

    rows = [
      {
        "reference_number" => "REF-CHUNK-#{SecureRandom.hex(4)}",
        "amount" => "1.00",
        "due_on" => "2030-04-01",
        "status" => "pending"
      }
    ]

    assert_no_difference("Receivable.count") do
      ImportChunkJob.perform_now(@batch.id, rows, 0)
    end

    @batch.reload
    assert_equal 1, @batch.failed_rows
    assert_includes @batch.row_errors.first["errors"].join, "simulated failure"
  end
end
