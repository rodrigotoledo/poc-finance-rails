# frozen_string_literal: true

module Api
  module V2
    class BaseController < ApplicationController
      include StrongerParameters::ControllerSupport::PermittedParameters

      include LocaleFromRequest

      permitted_parameters :all,
                           lang: Parameters.string,
                           locale: Parameters.string
    end
  end
end
