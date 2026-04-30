# frozen_string_literal: true

# == Schema Information
#
# Table name: credit_operations
#
#  id                             :bigint           not null, primary key
#  available_for_investment_cents :bigint
#  discarded_at                   :datetime
#  expected_return_rate           :decimal(7, 4)
#  funded_amount_cents            :bigint           not null
#  idempotency_key                :string
#  investment_end_date            :date
#  investment_start_date          :date
#  rate                           :decimal(7, 4)    not null
#  risk_rating                    :string
#  status                         :string           default("draft"), not null
#  total_invested_cents           :bigint           default(0), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  originator_id                  :bigint           not null
#  receivable_id                  :bigint           not null
#
# Indexes
#
#  index_credit_operations_on_discarded_at     (discarded_at)
#  index_credit_operations_on_idempotency_key  (idempotency_key) UNIQUE WHERE (discarded_at IS NULL)
#  index_credit_operations_on_originator_id    (originator_id)
#  index_credit_operations_on_receivable_id    (receivable_id)
#
# Foreign Keys
#
#  fk_rails_...  (originator_id => originators.id)
#  fk_rails_...  (receivable_id => receivables.id)
#
require "test_helper"

class CreditOperationTest < ActiveSupport::TestCase
  include ApiFixtures

  test "originator_matches_receivable skips when receivable is blank" do
    o = originators(:acme)
    op = CreditOperation.new(
      originator_id: o.id,
      receivable_id: nil,
      funded_amount_cents: 10_000,
      rate: 1.5,
      status: "draft"
    )
    op.valid?
    msg = I18n.t("activerecord.errors.models.credit_operation.attributes.originator_id.inconsistent_originator")
    assert_not_includes op.errors[:originator_id], msg
  end

  test "originator_matches_receivable skips when originator_id is blank" do
    r = create_receivable!(originator: originators(:acme))
    op = CreditOperation.new(
      receivable: r,
      originator_id: nil,
      funded_amount_cents: 10_000,
      rate: 1.5,
      status: "draft"
    )
    op.valid?
    msg = I18n.t("activerecord.errors.models.credit_operation.attributes.originator_id.inconsistent_originator")
    assert_not_includes op.errors[:originator_id], msg
  end

  test "inconsistent originator error uses i18n (en)" do
    originator = Originator.create!(legal_name: "A", tax_id: unique_tax_id)
    other = Originator.create!(legal_name: "B", tax_id: unique_tax_id)
    receivable = Receivable.create!(
      originator: originator,
      reference_number: "R-#{SecureRandom.hex(4)}",
      amount_cents: 10_000,
      due_on: Date.current,
      status: "pending"
    )
    op = CreditOperation.new(
      receivable: receivable,
      originator: other,
      funded_amount_cents: 10_000,
      rate: 1.5,
      status: "draft"
    )

    I18n.with_locale(:en) do
      assert_not op.valid?
      assert_includes op.errors[:originator_id], I18n.t(
        "activerecord.errors.models.credit_operation.attributes.originator_id.inconsistent_originator",
        locale: :en
      )
    end
  end

  test "inconsistent originator error uses i18n (pt-BR)" do
    originator = Originator.create!(legal_name: "A", tax_id: unique_tax_id)
    other = Originator.create!(legal_name: "B", tax_id: unique_tax_id)
    receivable = Receivable.create!(
      originator: originator,
      reference_number: "R-#{SecureRandom.hex(4)}",
      amount_cents: 10_000,
      due_on: Date.current,
      status: "pending"
    )
    op = CreditOperation.new(
      receivable: receivable,
      originator: other,
      funded_amount_cents: 10_000,
      rate: 1.5,
      status: "draft"
    )

    I18n.with_locale(:"pt-BR") do
      assert_not op.valid?
      assert_includes op.errors[:originator_id], I18n.t(
        "activerecord.errors.models.credit_operation.attributes.originator_id.inconsistent_originator",
        locale: :"pt-BR"
      )
    end
  end

end
