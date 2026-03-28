# frozen_string_literal: true

require "test_helper"

# Money and rates must stay exact: PostgreSQL DECIMAL/NUMERIC + integer cents, never REAL/DOUBLE.
# This test fails if a migration introduces a float column or mis-typed cent storage.
class FinancialColumnTypesTest < ActiveSupport::TestCase
  test "database has no float columns" do
    internal = %w[schema_migrations ar_internal_metadata]
    connection.tables.each do |table|
      next if internal.include?(table)

      connection.columns(table).each do |column|
        assert_not_equal :float, column.type,
          "#{table}.#{column.name}: use decimal or integer (e.g. *_cents), not float/real"
      end
    end
  end

  test "columns ending in _cents use integer storage" do
    internal = %w[schema_migrations ar_internal_metadata]
    connection.tables.each do |table|
      next if internal.include?(table)

      connection.columns(table).each do |column|
        next unless column.name.end_with?("_cents")

        assert_includes %i[integer bigint], column.type,
          "#{table}.#{column.name}: money must be stored as integer cents (bigint), not #{column.type}"
      end
    end
  end

  test "credit_operations.rate is decimal with expected precision" do
    column = CreditOperation.columns_hash.fetch("rate")
    assert_equal :decimal, column.type
    assert_equal 7, column.precision
    assert_equal 4, column.scale
  end

  private

  def connection
    ActiveRecord::Base.connection
  end
end
