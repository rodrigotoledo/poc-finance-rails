# frozen_string_literal: true

MoneyRails.configure do |config|
  config.default_currency = :brl
end

Money.locale_backend = :currency
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
