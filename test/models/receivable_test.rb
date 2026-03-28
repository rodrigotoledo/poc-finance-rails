# frozen_string_literal: true

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
