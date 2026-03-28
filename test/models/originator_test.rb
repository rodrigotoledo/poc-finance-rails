# frozen_string_literal: true

require "test_helper"

class OriginatorTest < ActiveSupport::TestCase
  test "is valid with legal_name and tax_id" do
    originator = Originator.new(legal_name: "Acme Ltd", tax_id: unique_tax_id)
    assert originator.valid?
  end

  test "requires unique tax_id among kept rows" do
    tid = unique_tax_id
    Originator.create!(legal_name: "First", tax_id: tid)
    duplicate = Originator.new(legal_name: "Second", tax_id: tid)
    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:tax_id, :taken)
  end

  test "discard soft-deletes" do
    originator = Originator.create!(legal_name: "Soft", tax_id: unique_tax_id)
    assert originator.discard
    assert_predicate originator.reload, :discarded?
    assert_not Originator.kept.exists?(originator.id)
  end

  private

  def unique_tax_id
    # 14 digits — synthetic CNPJ-style id for tests
    SecureRandom.random_number(10**14).to_s.rjust(14, "0")
  end
end
