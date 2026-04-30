# frozen_string_literal: true

require "test_helper"

module Api
  module V2
    class ExportsControllerTest < ActionDispatch::IntegrationTest
      test "POST create rejects missing required params" do
        post "/api/v2/exports", params: {}, as: :json
        assert_response :bad_request
        assert_includes response.body, "Invalid parameter"
      end

      test "POST create rejects invalid deliver_to_email type" do
        post "/api/v2/exports",
             params: { entity: "receivables", range: "all", deliver_to_email: 123 },
             as: :json
        assert_response :bad_request
        assert_includes response.body, "Invalid parameter"
      end
    end
  end
end

