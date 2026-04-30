# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include StrongerParameters::ControllerSupport::PermittedParameters

      include LocaleFromRequest
      include Api::V1::PaginatedJson
      include Api::IdempotencyFromHeaders

      permitted_parameters :all,
                           lang: Parameters.string,
                           locale: Parameters.string,
                           page: Parameters.integer & Parameters.gte(1),
                           per_page: Parameters.integer & Parameters.gte(1) & Parameters.lte(Api::V1::PaginatedJson::MAX_PER_PAGE),
                           q: Parameters.string,
                           status: Parameters.string

      private

      def q_text
        params[:q].to_s.strip
      end

      def q_like
        "%#{q_text}%"
      end

      # Useful for masked inputs (CNPJ/CPF) sent as "12.345.678/0001-90"
      def q_digits
        q_text.gsub(/\D+/, "")
      end

      def q_digits_like
        "%#{q_digits}%"
      end
    end
  end
end
