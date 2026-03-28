# frozen_string_literal: true

require "test_helper"

class CreditOperationTest < ActiveSupport::TestCase
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

  private

  def unique_tax_id
    SecureRandom.random_number(10**14).to_s.rjust(14, "0")
  end
end
