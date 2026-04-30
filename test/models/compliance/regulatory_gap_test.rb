# frozen_string_literal: true

# == Schema Information
#
# Table name: regulatory_gaps
#
#  id                  :bigint           not null, primary key
#  area                :string           not null
#  code                :string
#  description         :text
#  discarded_at        :datetime
#  idempotency_key     :string
#  severity            :string
#  status              :string           default("open"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  credit_operation_id :bigint
#
# Indexes
#
#  index_regulatory_gaps_on_credit_operation_id  (credit_operation_id)
#  index_regulatory_gaps_on_discarded_at         (discarded_at)
#  index_regulatory_gaps_on_idempotency_key      (idempotency_key) UNIQUE WHERE (discarded_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (credit_operation_id => credit_operations.id)
#
require "test_helper"

module Compliance
  class RegulatoryGapTest < ActiveSupport::TestCase
    test "requires area and status" do
      gap = RegulatoryGap.new(area: "regulation", status: "open")
      assert gap.valid?
    end
  end
end
