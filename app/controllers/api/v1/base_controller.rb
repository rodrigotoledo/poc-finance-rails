# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include LocaleFromRequest
      include Api::V1::PaginatedJson

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
