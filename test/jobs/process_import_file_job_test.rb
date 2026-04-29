# frozen_string_literal: true

require "test_helper"

class ProcessImportFileJobTest < ActiveJob::TestCase
  include ApiFixtures

  setup do
    @originator = originators(:acme)
  end

  test "loads csv enqueues chunk jobs and completes pipeline" do
    path = nil
    ref1 = "REF-PIF-#{SecureRandom.hex(4)}"
    ref2 = "REF-PIF-#{SecureRandom.hex(4)}"
    csv = <<~CSV
      reference_number,amount,due_on,status
      #{ref1},100.00,2030-06-01,pending
      #{ref2},200.00,2030-06-02,pending
    CSV

    path = write_temp_csv(csv)
    batch = ImportBatch.create!(
      filename: "pipe.csv",
      file_path: path,
      file_type: "csv",
      status: "pending",
      originator: @originator
    )

    assert_enqueued_jobs 1, only: ImportChunkJob do
      ProcessImportFileJob.new.perform(batch.id)
    end

    batch.reload
    assert_equal "processing", batch.status
    assert_equal 2, batch.total_rows

    perform_enqueued_jobs

    batch.reload
    assert_equal "completed", batch.status
    assert_equal 2, batch.processed_rows
    assert_equal 0, batch.failed_rows
    assert Receivable.exists?(reference_number: ref1)
    assert Receivable.exists?(reference_number: ref2)
  ensure
    FileUtils.rm_f(path) if path
  end

  test "header only csv marks batch failed and zero rows" do
    path = nil
    csv = "reference_number,amount,due_on,status\n"
    path = write_temp_csv(csv)
    batch = ImportBatch.create!(
      filename: "empty.csv",
      file_path: path,
      file_type: "csv",
      status: "pending",
      originator: @originator
    )

    ProcessImportFileJob.new.perform(batch.id)

    batch.reload
    assert_equal "failed", batch.status
    assert_equal 0, batch.total_rows
    assert_no_enqueued_jobs only: ImportChunkJob
  ensure
    FileUtils.rm_f(path) if path
  end

  test "loads xlsx and completes chunk pipeline" do
    require "axlsx"

    path = nil
    ref = "REF-XLSX-#{SecureRandom.hex(4)}"
    path = Rails.root.join("tmp", "test_import_#{SecureRandom.hex(8)}.xlsx").to_s
    package = Axlsx::Package.new
    sheet = package.workbook.add_worksheet(name: "Receivables")
    sheet.add_row %w[reference_number amount due_on status]
    sheet.add_row [ ref, "30.00", "2030-09-01", "pending" ]
    package.serialize(path)

    batch = ImportBatch.create!(
      filename: "sheet.xlsx",
      file_path: path,
      file_type: "xlsx",
      status: "pending",
      originator: @originator
    )

    assert_enqueued_jobs 1, only: ImportChunkJob do
      ProcessImportFileJob.new.perform(batch.id)
    end

    perform_enqueued_jobs

    batch.reload
    assert_equal "completed", batch.status
    assert Receivable.exists?(reference_number: ref)
  ensure
    FileUtils.rm_f(path) if path
  end

  test "load_rows returns empty array for unsupported file_type" do
    job = ProcessImportFileJob.new
    fake_batch = Struct.new(:file_type, :file_path).new("unknown", "/tmp/unused")

    assert_equal [], job.send(:load_rows, fake_batch)
  end

  test "rescued error marks batch failed and re-raises" do
    path = write_temp_csv("reference_number,amount,due_on,status\nX,1,2030-01-01,pending\n")
    batch = ImportBatch.create!(
      filename: "bad.csv",
      file_path: path,
      file_type: "csv",
      status: "pending",
      originator: @originator
    )

    ProcessImportFileJob.any_instance.stubs(:load_rows).raises(RuntimeError.new("load failed"))

    error = assert_raises(RuntimeError) { ProcessImportFileJob.new.perform(batch.id) }
    assert_equal "load failed", error.message
    assert_equal "failed", batch.reload.status
  ensure
    FileUtils.rm_f(path) if path
  end

  test "perform raises RecordNotFound when batch id does not exist" do
    missing_id = (ImportBatch.maximum(:id) || 0) + 10_000

    assert_raises(ActiveRecord::RecordNotFound) do
      ProcessImportFileJob.new.perform(missing_id)
    end
  end

  private

  def write_temp_csv(content)
    path = Rails.root.join("tmp", "test_import_#{SecureRandom.hex(8)}.csv").to_s
    File.write(path, content)
    path
  end
end
