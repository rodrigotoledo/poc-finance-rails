# frozen_string_literal: true

# == Schema Information
#
# Table name: receivables
#
#  id                     :bigint           not null, primary key
#  amount_cents           :bigint           not null
#  collateral_value_cents :bigint
#  discarded_at           :datetime
#  discount_rate          :decimal(7, 4)
#  due_on                 :date             not null
#  idempotency_key        :string
#  reference_number       :string           not null
#  risk_weight            :decimal(5, 2)
#  status                 :string           default("pending"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  originator_id          :bigint           not null
#
# Indexes
#
#  index_receivables_on_discarded_at           (discarded_at)
#  index_receivables_on_idempotency_key        (idempotency_key) UNIQUE WHERE (discarded_at IS NULL)
#  index_receivables_on_originator_id          (originator_id)
#  index_receivables_on_originator_ref_active  (originator_id,reference_number) UNIQUE WHERE (discarded_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (originator_id => originators.id)
#
require "test_helper"

class ReceivableTest < ActiveSupport::TestCase
  test "is valid with originator and monetized amount" do
    originator = Originator.create!(legal_name: "Holder", tax_id: unique_tax_id)
    receivable = Receivable.new(
      originator: originator,
      reference_number: "REF-#{SecureRandom.hex(4)}",
      amount_cents: 50_000,
      due_on: Date.current + 30,
      status: "pending"
    )
    assert receivable.valid?
    assert_equal Money.new(50_000, :brl), receivable.amount
  end

  private

  def unique_tax_id
    SecureRandom.random_number(10**14).to_s.rjust(14, "0")
  end
end
