# frozen_string_literal: true

module ApiFixtures
  def unique_tax_id
    SecureRandom.random_number(10**14).to_s.rjust(14, "0")
  end

  def create_originator!(legal_name: "Fixture Co", tax_id: nil)
    Originator.create!(legal_name: legal_name, tax_id: tax_id || unique_tax_id)
  end

  def create_receivable!(originator:, reference_number: nil, **attrs)
    Receivable.create!(
      {
        originator: originator,
        reference_number: reference_number || "REF-#{SecureRandom.hex(4)}",
        amount_cents: 10_000,
        due_on: Date.current + 30,
        status: "pending"
      }.merge(attrs)
    )
  end

  def create_credit_operation!(receivable:, originator:, **attrs)
    CreditOperation.create!(
      {
        receivable: receivable,
        originator: originator,
        funded_amount_cents: 10_000,
        rate: 1.5,
        status: "draft"
      }.merge(attrs)
    )
  end

  def create_regulatory_gap!(area: "regulation", status: "open", **attrs)
    Compliance::RegulatoryGap.create!({ area: area, status: status }.merge(attrs))
  end
end
