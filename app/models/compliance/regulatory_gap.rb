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
module Compliance
  class RegulatoryGap < ApplicationRecord
    self.table_name = "regulatory_gaps"

    include Discard::Model
    include HasIdempotencyKey
    include Publishable

    def self.event_entity = "regulatory_gaps"

    belongs_to :credit_operation, optional: true

    validates :area, presence: true
    validates :status, presence: true

    has_idempotency_key
  end
end
