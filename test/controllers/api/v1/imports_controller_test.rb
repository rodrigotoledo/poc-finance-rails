# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ImportsControllerTest < ActionDispatch::IntegrationTest
      include ActiveJob::TestHelper

      setup do
        @originator = originators(:acme)
      end

      test "POST create without file returns unprocessable" do
        assert_no_difference("ImportBatch.count") do
          post "/api/v1/imports", params: { originator_id: @originator.id }
        end
        assert_response :unprocessable_entity
        body = JSON.parse(response.body)
        assert_equal "File is required.", body["error"]
      end

      test "POST create with unsupported extension returns unprocessable" do
        file = Rack::Test::UploadedFile.new(
          StringIO.new("x"),
          "application/octet-stream",
          original_filename: "data.txt"
        )
        assert_no_difference("ImportBatch.count") do
          post "/api/v1/imports", params: { file: file, originator_id: @originator.id }
        end
        assert_response :unprocessable_entity
        body = JSON.parse(response.body)
        assert_equal "Unsupported file format.", body["error"]
      end

      test "POST create persists batch enqueues job and returns created" do
        ref = "REF-API-#{SecureRandom.hex(4)}"
        csv = <<~CSV
          reference_number,amount,due_on,status
          #{ref},50.00,2030-07-01,pending
        CSV

        file = temp_csv_upload(csv, "upload.csv")

        assert_difference("ImportBatch.count", 1) do
          assert_enqueued_with(job: ProcessImportFileJob) do
            post "/api/v1/imports", params: { file: file, originator_id: @originator.id }
          end
        end

        assert_response :created
        body = JSON.parse(response.body)
        assert_equal "pending", body["status"]
        assert_equal "csv", body["file_type"]
        assert_equal "upload.csv", body["filename"]
        assert_equal @originator.id, body["originator_id"]

        drain_enqueued_jobs

        batch = ImportBatch.order(:id).last
        assert_equal "completed", batch.status
        assert Receivable.exists?(reference_number: ref)
      end

      test "GET show returns batch" do
        batch = ImportBatch.create!(
          filename: "x.csv",
          file_path: "/tmp/x.csv",
          file_type: "csv",
          status: "pending",
          originator: @originator
        )
        get "/api/v1/imports/#{batch.id}"
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal batch.id, body["id"]
        assert_equal "pending", body["status"]
      end

      test "GET show returns not found for unknown id" do
        get "/api/v1/imports/9_999_999_999"
        assert_response :not_found
      end

      test "GET index lists batches" do
        ImportBatch.create!(
          filename: "a.csv",
          file_path: "/tmp/a.csv",
          file_type: "csv",
          status: "completed",
          originator: @originator,
          total_rows: 1,
          processed_rows: 1
        )
        get "/api/v1/imports"
        assert_response :success
        body = JSON.parse(response.body)
        assert body.key?("data")
        assert body["data"].any? { |b| b["filename"] == "a.csv" }
      end

      private

      def temp_csv_upload(content, original_filename)
        tf = Tempfile.new([ "import", ".csv" ])
        tf.write(content)
        tf.close
        Rack::Test::UploadedFile.new(tf.path, "text/csv", original_filename: original_filename)
      end
    end
  end
end
