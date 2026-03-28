# frozen_string_literal: true

require "test_helper"

module Compliance
  class RegulatoryGapTest < ActiveSupport::TestCase
    test "requires area and status" do
      gap = RegulatoryGap.new(area: "regulation", status: "open")
      assert gap.valid?
    end
  end
end
