# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    # Locale resolution via LocaleFromRequest on Api::V1::BaseController — exercised through OriginatorsController.
    class LocaleFromRequestTest < ActionDispatch::IntegrationTest
      test "default locale is English without lang locale or Accept-Language" do
        post "/api/v1/originators",
             params: { originator: { legal_name: "", tax_id: "" } },
             as: :json
        assert_response :unprocessable_entity
        msg = JSON.parse(response.body)["errors"].join
        assert_match(/blank|can't/i, msg.downcase)
      end

      test "lang=pt-br uses Portuguese for presence errors" do
        post "/api/v1/originators?lang=pt-br",
             params: { originator: { legal_name: "", tax_id: "" } },
             as: :json
        assert_response :unprocessable_entity
        msg = JSON.parse(response.body)["errors"].join
        assert_includes msg.downcase, "branco"
      end

      test "Accept-Language pt-BR returns Portuguese for duplicate tax_id" do
        tid = unique_tid
        post "/api/v1/originators",
             params: { originator: { legal_name: "First", tax_id: tid } },
             headers: { "Accept-Language" => "pt-BR" },
             as: :json
        assert_response :created

        post "/api/v1/originators",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             headers: { "Accept-Language" => "pt-BR" },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join, "já está em uso"
      end

      test "locale=en forces English for duplicate tax_id" do
        tid = unique_tid
        post "/api/v1/originators?locale=en",
             params: { originator: { legal_name: "First", tax_id: tid } },
             as: :json
        assert_response :created

        post "/api/v1/originators?locale=en",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join.downcase, "taken"
      end

      test "lang=pt-br returns Portuguese for duplicate tax_id" do
        tid = unique_tid
        post "/api/v1/originators?lang=pt-br",
             params: { originator: { legal_name: "First", tax_id: tid } },
             as: :json
        assert_response :created

        post "/api/v1/originators?lang=pt-br",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join, "já está em uso"
      end

      test "lang=PT-BR returns Portuguese for duplicate tax_id" do
        tid = unique_tid
        post "/api/v1/originators?lang=PT-BR",
             params: { originator: { legal_name: "First", tax_id: tid } },
             as: :json
        assert_response :created

        post "/api/v1/originators?lang=PT-BR",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join, "já está em uso"
      end

      test "invalid lang forces English and ignores locale and Accept-Language" do
        tid = unique_tid
        post "/api/v1/originators?lang=fr&locale=pt-BR",
             params: { originator: { legal_name: "First", tax_id: tid } },
             headers: { "Accept-Language" => "pt-BR" },
             as: :json
        assert_response :created

        post "/api/v1/originators?lang=fr&locale=pt-BR",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             headers: { "Accept-Language" => "pt-BR" },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join.downcase, "taken"
      end

      test "blank lang falls through to locale param" do
        tid = unique_tid
        post "/api/v1/originators?lang=&locale=pt-BR",
             params: { originator: { legal_name: "First", tax_id: tid } },
             as: :json
        assert_response :created

        post "/api/v1/originators?lang=&locale=pt-BR",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join, "já está em uso"
      end

      test "locale=pt-BR without lang uses Portuguese" do
        tid = unique_tid
        post "/api/v1/originators?locale=pt-BR",
             params: { originator: { legal_name: "First", tax_id: tid } },
             as: :json
        assert_response :created

        post "/api/v1/originators?locale=pt-BR",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join, "já está em uso"
      end

      test "invalid locale falls through to Accept-Language" do
        tid = unique_tid
        post "/api/v1/originators?locale=fr",
             params: { originator: { legal_name: "First", tax_id: tid } },
             headers: { "Accept-Language" => "pt-BR" },
             as: :json
        assert_response :created

        post "/api/v1/originators?locale=fr",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             headers: { "Accept-Language" => "pt-BR" },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join, "já está em uso"
      end

      test "Accept-Language first matching tag wins" do
        tid = unique_tid
        post "/api/v1/originators",
             params: { originator: { legal_name: "First", tax_id: tid } },
             headers: { "Accept-Language" => "pt-BR,en;q=0.9" },
             as: :json
        assert_response :created

        post "/api/v1/originators",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             headers: { "Accept-Language" => "pt-BR,en;q=0.9" },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join, "já está em uso"
      end

      test "Accept-Language skips unknown tags until en" do
        tid = unique_tid
        post "/api/v1/originators",
             params: { originator: { legal_name: "First", tax_id: tid } },
             headers: { "Accept-Language" => "fr,de,en" },
             as: :json
        assert_response :created

        post "/api/v1/originators",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             headers: { "Accept-Language" => "fr,de,en" },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join.downcase, "taken"
      end

      test "Accept-Language with no matching tags uses default locale" do
        post "/api/v1/originators",
             params: { originator: { legal_name: "", tax_id: "" } },
             headers: { "Accept-Language" => "fr,de,es" },
             as: :json
        assert_response :unprocessable_entity
        msg = JSON.parse(response.body)["errors"].join
        assert_match(/blank|can't/i, msg.downcase)
      end

      test "lang takes precedence over locale query param" do
        tid = unique_tid
        post "/api/v1/originators?lang=en&locale=pt-BR",
             params: { originator: { legal_name: "First", tax_id: tid } },
             as: :json
        assert_response :created

        post "/api/v1/originators?lang=en&locale=pt-BR",
             params: { originator: { legal_name: "Second", tax_id: tid } },
             as: :json
        assert_response :unprocessable_entity
        assert_includes JSON.parse(response.body)["errors"].join.downcase, "taken"
      end

      private

      def unique_tid
        SecureRandom.random_number(10**14).to_s.rjust(14, "0")
      end
    end
  end
end
