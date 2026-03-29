# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ReceivablesControllerTest < ActionDispatch::IntegrationTest
      test "GET index returns success" do
        get "/api/v1/receivables"
        assert_response :success
      end

      test "GET index excludes discarded receivables" do
        get "/api/v1/receivables"
        assert_response :success
        ids = JSON.parse(response.body)["data"].map { |row| row["id"] }
        assert_not_includes ids, receivables(:discarded_receivable).id
        assert_includes ids, receivables(:ref_acme_001).id
      end

      test "GET index includes receivable with originator" do
        o = create_originator!
        r = create_receivable!(originator: o, reference_number: "IDX-#{SecureRandom.hex(2)}")
        get "/api/v1/receivables"
        assert_response :success
        rows = JSON.parse(response.body)["data"]
        found = rows.find { |row| row["id"] == r.id }
        assert found
        assert_equal o.id, found["originator"]["id"]
      end

      test "GET index filters by originator_id" do
        o1 = create_originator!
        o2 = create_originator!
        r1 = create_receivable!(originator: o1, reference_number: "F1-#{SecureRandom.hex(2)}")
        create_receivable!(originator: o2, reference_number: "F2-#{SecureRandom.hex(2)}")
        get "/api/v1/receivables", params: { originator_id: o1.id }
        assert_response :success
        ids = JSON.parse(response.body)["data"].map { |row| row["id"] }
        assert_includes ids, r1.id
        assert_equal 1, ids.size
      end

      test "POST create creates receivable" do
        o = create_originator!
        assert_difference("Receivable.count", 1) do
          post "/api/v1/receivables",
               params: {
                 receivable: {
                   originator_id: o.id,
                   reference_number: "NEW-#{SecureRandom.hex(4)}",
                   amount_cents: 25_000,
                   due_on: Date.current + 10,
                   status: "pending"
                 }
               },
               as: :json
        end
        assert_response :created
        body = JSON.parse(response.body)
        assert_equal 25_000, body["amount_cents"]
      end

      test "GET show returns receivable with originator" do
        o = create_originator!
        r = create_receivable!(originator: o)
        get "/api/v1/receivables/#{r.id}"
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal r.id, body["id"]
        assert_equal o.id, body["originator"]["id"]
      end

      test "GET show returns 404 for unknown id" do
        get "/api/v1/receivables/999_999_999"
        assert_response :not_found
      end

      test "GET show returns 404 when receivable discarded" do
        o = create_originator!
        r = create_receivable!(originator: o)
        r.discard!
        get "/api/v1/receivables/#{r.id}"
        assert_response :not_found
      end

      test "POST create returns unprocessable on duplicate reference_number for same originator" do
        o = create_originator!
        ref = "DUP-#{SecureRandom.hex(2)}"
        create_receivable!(originator: o, reference_number: ref)
        assert_no_difference("Receivable.count") do
          post "/api/v1/receivables",
               params: {
                 receivable: {
                   originator_id: o.id,
                   reference_number: ref,
                   amount_cents: 5_000,
                   due_on: Date.current,
                   status: "pending"
                 }
               },
               as: :json
        end
        assert_response :unprocessable_entity
      end

      test "POST create returns unprocessable when status invalid" do
        o = create_originator!
        assert_no_difference("Receivable.count") do
          post "/api/v1/receivables",
               params: {
                 receivable: {
                   originator_id: o.id,
                   reference_number: "INV-#{SecureRandom.hex(4)}",
                   amount_cents: 1_000,
                   due_on: Date.current,
                   status: "not_a_valid_status"
                 }
               },
               as: :json
        end
        assert_response :unprocessable_entity
      end

      test "PATCH update returns unprocessable when status invalid" do
        o = create_originator!
        r = create_receivable!(originator: o)
        patch "/api/v1/receivables/#{r.id}",
              params: { receivable: { status: "invalid" } },
              as: :json
        assert_response :unprocessable_entity
      end

      test "PATCH update returns 404 when receivable discarded" do
        o = create_originator!
        r = create_receivable!(originator: o)
        r.discard!
        patch "/api/v1/receivables/#{r.id}",
              params: { receivable: { status: "eligible" } },
              as: :json
        assert_response :not_found
      end

      test "PATCH update updates receivable" do
        o = create_originator!
        r = create_receivable!(originator: o)
        patch "/api/v1/receivables/#{r.id}",
              params: { receivable: { status: "eligible" } },
              as: :json
        assert_response :success
        assert_equal "eligible", r.reload.status
      end

      test "DELETE destroy soft-deletes" do
        o = create_originator!
        r = create_receivable!(originator: o)
        assert_difference("Receivable.kept.count", -1) do
          delete "/api/v1/receivables/#{r.id}"
        end
        assert_response :no_content
        assert_predicate r.reload, :discarded?
      end

      test "DELETE destroy returns unprocessable when discard fails" do
        o = create_originator!
        r = create_receivable!(originator: o)
        Receivable.any_instance.stubs(:discard).returns(false)
        delete "/api/v1/receivables/#{r.id}"
        assert_response :unprocessable_entity
      end
    end
  end
end
