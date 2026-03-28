# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class RegulatoryGapsControllerTest < ActionDispatch::IntegrationTest
      test "GET index returns success" do
        get "/api/v1/regulatory_gaps"
        assert_response :success
      end

      test "GET index filters by credit_operation_id" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        gap = Compliance::RegulatoryGap.create!(
          area: "regulation",
          status: "open",
          credit_operation: op
        )
        get "/api/v1/regulatory_gaps", params: { credit_operation_id: op.id }
        assert_response :success
        rows = JSON.parse(response.body)
        assert_equal 1, rows.size
        assert_equal gap.id, rows.first["id"]
      end

      test "POST create creates regulatory gap without credit operation" do
        assert_difference("Compliance::RegulatoryGap.count", 1) do
          post "/api/v1/regulatory_gaps",
               params: {
                 regulatory_gap: {
                   area: "security",
                   code: "G-1",
                   description: "Sample",
                   severity: "high",
                   status: "open"
                 }
               },
               as: :json
        end
        assert_response :created
        body = JSON.parse(response.body)
        assert_equal "security", body["area"]
        assert_nil body["credit_operation_id"]
      end

      test "POST create links credit_operation when given" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        post "/api/v1/regulatory_gaps",
             params: {
               regulatory_gap: {
                 area: "regulation",
                 status: "open",
                 credit_operation_id: op.id
               }
             },
             as: :json
        assert_response :created
        assert_equal op.id, JSON.parse(response.body)["credit_operation_id"]
      end

      test "GET show returns gap" do
        gap = Compliance::RegulatoryGap.create!(area: "quality", status: "open")
        get "/api/v1/regulatory_gaps/#{gap.id}"
        assert_response :success
        assert_equal gap.id, JSON.parse(response.body)["id"]
      end

      test "GET show returns 404 for unknown id" do
        get "/api/v1/regulatory_gaps/999_999_999"
        assert_response :not_found
      end

      test "GET show returns 404 when gap discarded" do
        gap = Compliance::RegulatoryGap.create!(area: "quality", status: "open")
        gap.discard!
        get "/api/v1/regulatory_gaps/#{gap.id}"
        assert_response :not_found
      end

      test "GET index excludes discarded gaps" do
        kept = Compliance::RegulatoryGap.create!(area: "a", status: "open")
        gone = Compliance::RegulatoryGap.create!(area: "b", status: "open")
        gone.discard!
        get "/api/v1/regulatory_gaps"
        assert_response :success
        ids = JSON.parse(response.body).map { |row| row["id"] }
        assert_includes ids, kept.id
        assert_not_includes ids, gone.id
      end

      test "POST create returns unprocessable when area blank" do
        assert_no_difference("Compliance::RegulatoryGap.count") do
          post "/api/v1/regulatory_gaps",
               params: { regulatory_gap: { area: "", status: "open" } },
               as: :json
        end
        assert_response :unprocessable_entity
      end

      test "POST create returns unprocessable when status blank" do
        assert_no_difference("Compliance::RegulatoryGap.count") do
          post "/api/v1/regulatory_gaps",
               params: { regulatory_gap: { area: "x", status: "" } },
               as: :json
        end
        assert_response :unprocessable_entity
      end

      test "PATCH update returns 404 when gap discarded" do
        gap = Compliance::RegulatoryGap.create!(area: "quality", status: "open")
        gap.discard!
        patch "/api/v1/regulatory_gaps/#{gap.id}",
              params: { regulatory_gap: { status: "closed" } },
              as: :json
        assert_response :not_found
      end

      test "PATCH update updates gap" do
        gap = Compliance::RegulatoryGap.create!(area: "quality", status: "open")
        patch "/api/v1/regulatory_gaps/#{gap.id}",
              params: { regulatory_gap: { status: "closed" } },
              as: :json
        assert_response :success
        assert_equal "closed", gap.reload.status
      end

      test "PATCH update returns unprocessable when area blank" do
        gap = Compliance::RegulatoryGap.create!(area: "quality", status: "open")
        patch "/api/v1/regulatory_gaps/#{gap.id}",
              params: { regulatory_gap: { area: "" } },
              as: :json
        assert_response :unprocessable_entity
        assert JSON.parse(response.body)["errors"].present?
      end

      test "DELETE destroy soft-deletes" do
        gap = Compliance::RegulatoryGap.create!(area: "infra", status: "open")
        assert_difference("Compliance::RegulatoryGap.kept.count", -1) do
          delete "/api/v1/regulatory_gaps/#{gap.id}"
        end
        assert_response :no_content
        assert_predicate gap.reload, :discarded?
      end

      test "DELETE destroy returns unprocessable when discard fails" do
        gap = Compliance::RegulatoryGap.create!(area: "infra", status: "open")
        Compliance::RegulatoryGap.any_instance.stubs(:discard).returns(false)
        delete "/api/v1/regulatory_gaps/#{gap.id}"
        assert_response :unprocessable_entity
      end
    end
  end
end
