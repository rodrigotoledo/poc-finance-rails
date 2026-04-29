# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class CreditOperationsControllerTest < ActionDispatch::IntegrationTest
      test "GET index returns success" do
        get "/api/v1/credit_operations"
        assert_response :success
      end

      test "GET index excludes discarded credit operations" do
        get "/api/v1/credit_operations"
        assert_response :success
        ids = JSON.parse(response.body)["data"].map { |row| row["id"] }
        assert_not_includes ids, credit_operations(:discarded_op).id
        assert_includes ids, credit_operations(:op_draft).id
      end

      test "GET index lists credit operation with associations" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        get "/api/v1/credit_operations"
        assert_response :success
        rows = JSON.parse(response.body)["data"]
        found = rows.find { |row| row["id"] == op.id }
        assert found
        assert_equal r.id, found["receivable"]["id"]
        assert_equal o.id, found["originator"]["id"]
      end

      test "GET index filters by originator_id and receivable_id" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        get "/api/v1/credit_operations", params: { originator_id: o.id }
        assert_response :success
        assert_equal 1, JSON.parse(response.body)["data"].size

        get "/api/v1/credit_operations", params: { receivable_id: r.id }
        assert_response :success
        ids = JSON.parse(response.body)["data"].map { |row| row["id"] }
        assert_includes ids, op.id
        assert_equal 1, ids.size
      end

      test "POST create creates operation when originator matches receivable" do
        o = create_originator!
        r = create_receivable!(originator: o)
        assert_difference("CreditOperation.count", 1) do
          post "/api/v1/credit_operations",
               params: {
                 credit_operation: {
                   receivable_id: r.id,
                   originator_id: o.id,
                   funded_amount_cents: 8_000,
                   rate: 2.0,
                   status: "draft"
                 }
               },
               as: :json
        end
        assert_response :created
        assert_equal 8_000, JSON.parse(response.body)["funded_amount_cents"]
      end

      test "POST create returns unprocessable when originator mismatches receivable" do
        o1 = create_originator!
        o2 = create_originator!
        r = create_receivable!(originator: o1)
        assert_no_difference("CreditOperation.count") do
          post "/api/v1/credit_operations",
               params: {
                 credit_operation: {
                   receivable_id: r.id,
                   originator_id: o2.id,
                   funded_amount_cents: 8_000,
                   rate: 2.0,
                   status: "draft"
                 }
               },
               as: :json
        end
        assert_response :unprocessable_entity
        assert JSON.parse(response.body)["errors"].present?
      end

      test "GET show returns credit operation" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        get "/api/v1/credit_operations/#{op.id}"
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal op.id, body["id"]
        assert_equal r.id, body["receivable"]["id"]
      end

      test "GET show returns 404 for unknown id" do
        get "/api/v1/credit_operations/999_999_999"
        assert_response :not_found
      end

      test "GET show returns 404 when operation discarded" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        op.discard!
        get "/api/v1/credit_operations/#{op.id}"
        assert_response :not_found
      end

      test "GET index filters by both originator_id and receivable_id" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        get "/api/v1/credit_operations",
            params: { originator_id: o.id, receivable_id: r.id }
        assert_response :success
        rows = JSON.parse(response.body)["data"]
        assert_equal 1, rows.size
        assert_equal op.id, rows.first["id"]
      end

      test "PATCH update returns unprocessable when status invalid" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        patch "/api/v1/credit_operations/#{op.id}",
              params: { credit_operation: { status: "not_valid" } },
              as: :json
        assert_response :unprocessable_entity
      end

      test "PATCH update returns 404 when operation discarded" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        op.discard!
        patch "/api/v1/credit_operations/#{op.id}",
              params: { credit_operation: { status: "approved" } },
              as: :json
        assert_response :not_found
      end

      test "PATCH update updates status" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        patch "/api/v1/credit_operations/#{op.id}",
              params: { credit_operation: { status: "approved" } },
              as: :json
        assert_response :success
        assert_equal "approved", op.reload.status
      end

      test "DELETE destroy soft-deletes" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        assert_difference("CreditOperation.kept.count", -1) do
          delete "/api/v1/credit_operations/#{op.id}"
        end
        assert_response :no_content
        assert_predicate op.reload, :discarded?
      end

      test "DELETE destroy returns unprocessable when discard fails" do
        o = create_originator!
        r = create_receivable!(originator: o)
        op = create_credit_operation!(receivable: r, originator: o)
        CreditOperation.any_instance.stubs(:discard).returns(false)
        delete "/api/v1/credit_operations/#{op.id}"
        assert_response :unprocessable_entity
      end
    end
  end
end
