# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"

  SimpleCov.start "rails" do
    enable_coverage :branch
    add_filter "/test/"
    add_filter "/vendor/"
    add_filter "/config/"
    add_group "Models", "app/models"
    add_group "Controllers", "app/controllers"
    add_group "Services", "app/services"

    formatter SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::SimpleFormatter,
        SimpleCov::Formatter::HTMLFormatter
      ]
    )
  end
end

ENV["RAILS_ENV"] ||= "test"
ENV["PARALLEL_WORKERS"] = "1" if ENV["COVERAGE"] == "true" || ENV["GUARD"] == "1" || ENV["CI"].present?

require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |f| require f }

module ActiveSupport
  class TestCase
    include ApiFixtures
    fixtures :all
    parallelize(
      workers: ENV["PARALLEL_WORKERS"] ? Integer(ENV["PARALLEL_WORKERS"]) : :number_of_processors
    )

    # Add more helper methods to be used for all tests here...
  end
end
