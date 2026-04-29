# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class OriginatorsControllerTest < ActionDispatch::IntegrationTest
      test "GET index returns success" do
        get "/api/v1/originators"
        assert_response :success
      end

      test "GET index excludes discarded originators" do
        get "/api/v1/originators"
        assert_response :success
        body = JSON.parse(response.body)
        assert body.key?("data")
        assert body.key?("meta")
        ids = body["data"].map { |row| row["id"] }
        assert_not_includes ids, originators(:discarded_one).id
        assert_includes ids, originators(:acme).id
      end

      test "GET index returns pagination meta" do
        get "/api/v1/originators"
        assert_response :success
        meta = JSON.parse(response.body)["meta"]
        assert_equal %w[page per_page total_count total_pages], meta.keys.sort
        assert meta["page"] >= 1
        assert meta["total_pages"] >= 1
      end

      test "GET index returns created originators as json" do
        o = create_originator!(legal_name: "Listed Co")
        get "/api/v1/originators"
        assert_response :success
        body = JSON.parse(response.body)
        ids = body["data"].map { |row| row["id"] }
        assert_includes ids, o.id
      end

      test "POST create returns created and persists" do
        tid = unique_tax_id
        assert_difference("Originator.count", 1) do
          post "/api/v1/originators",
               params: { originator: { legal_name: "API Originator", tax_id: tid } },
               as: :json
        end
        assert_response :created
        body = JSON.parse(response.body)
        assert_equal "API Originator", body["legal_name"]
        assert_equal tid, body["tax_id"]
      end

      test "POST create is idempotent with Idempotency-Key" do
        tid = unique_tax_id
        key = SecureRandom.uuid

        assert_difference("Originator.count", 1) do
          post "/api/v1/originators",
               params: { originator: { legal_name: "Idempotent", tax_id: tid } },
               headers: { "Idempotency-Key" => key },
               as: :json
        end
        assert_response :created
        first_id = JSON.parse(response.body)["id"]

        assert_no_difference("Originator.count") do
          post "/api/v1/originators",
               params: { originator: { legal_name: "Idempotent", tax_id: tid } },
               headers: { "Idempotency-Key" => key },
               as: :json
        end
        assert_response :created
        assert_equal first_id, JSON.parse(response.body)["id"]
      end

      test "GET show returns originator" do
        o = create_originator!
        get "/api/v1/originators/#{o.id}"
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal o.id, body["id"]
        assert_equal o.tax_id, body["tax_id"]
      end

      test "GET show returns 404 for unknown id" do
        get "/api/v1/originators/999_999_999"
        assert_response :not_found
      end

      test "GET show returns 404 when originator was discarded" do
        o = create_originator!
        o.discard!
        get "/api/v1/originators/#{o.id}"
        assert_response :not_found
      end

      test "POST create returns unprocessable when attributes invalid" do
        assert_no_difference("Originator.count") do
          post "/api/v1/originators",
               params: { originator: { legal_name: "", tax_id: "" } },
               as: :json
        end
        assert_response :unprocessable_entity
        assert JSON.parse(response.body)["errors"].present?
      end

      test "POST create returns unprocessable when tax_id duplicate among kept" do
        tid = unique_tax_id
        create_originator!(tax_id: tid)
        assert_no_difference("Originator.count") do
          post "/api/v1/originators",
               params: { originator: { legal_name: "Dup", tax_id: tid } },
               as: :json
        end
        assert_response :unprocessable_entity
      end

      test "PATCH update returns 404 when originator discarded" do
        o = create_originator!
        o.discard!
        patch "/api/v1/originators/#{o.id}",
              params: { originator: { legal_name: "Nope", tax_id: o.tax_id } },
              as: :json
        assert_response :not_found
      end

      test "DELETE destroy returns 404 when already discarded" do
        o = create_originator!
        o.discard!
        delete "/api/v1/originators/#{o.id}"
        assert_response :not_found
      end

      test "PATCH update changes attributes" do
        o = create_originator!
        patch "/api/v1/originators/#{o.id}",
              params: { originator: { legal_name: "Updated Name", tax_id: o.tax_id } },
              as: :json
        assert_response :success
        assert_equal "Updated Name", JSON.parse(response.body)["legal_name"]
        assert_equal "Updated Name", o.reload.legal_name
      end

      test "PATCH update returns unprocessable on invalid data" do
        o = create_originator!
        other = create_originator!
        patch "/api/v1/originators/#{o.id}",
              params: { originator: { legal_name: "X", tax_id: other.tax_id } },
              as: :json
        assert_response :unprocessable_entity
        assert JSON.parse(response.body)["errors"].present?
      end

      test "DELETE destroy soft-deletes" do
        o = create_originator!
        assert_difference("Originator.kept.count", -1) do
          delete "/api/v1/originators/#{o.id}"
        end
        assert_response :no_content
        assert_predicate o.reload, :discarded?
      end

      test "DELETE destroy returns unprocessable when discard fails" do
        o = create_originator!
        Originator.any_instance.stubs(:discard).returns(false)
        delete "/api/v1/originators/#{o.id}"
        assert_response :unprocessable_entity
      end
    end
  end
end
