# frozen_string_literal: true

# Sets I18n.locale from query params (+lang+, +locale+) or +Accept-Language+ (API).
#
# Priority:
# 1. +lang+ — if present and matches {I18n.available_locales}, use it; if present but invalid, +default_locale+ (+en+).
# 2. +locale+ — same matching rules, no "invalid forces default" (backward compatible).
# 3. +Accept-Language+ header.
# 4. +I18n.default_locale+.
module LocaleFromRequest
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&)
    I18n.with_locale(resolve_locale, &)
  end

  def resolve_locale
    if params.key?(:lang) && params[:lang].present?
      locale = normalize_locale_string(params[:lang])
      return locale if locale

      return I18n.default_locale
    end

    locale = normalize_locale_string(params[:locale])
    return locale if locale

    header = request.headers["Accept-Language"]
    return I18n.default_locale if header.blank?

    header.split(",").each do |part|
      tag = part.split(";").first.to_s.strip
      locale = normalize_locale_string(tag)
      return locale if locale
    end

    I18n.default_locale
  end

  def normalize_locale_string(value)
    return nil if value.blank?

    raw = value.to_s.strip
    I18n.available_locales.find do |loc|
      loc_s = loc.to_s
      loc_s.casecmp?(raw) ||
        loc_s.tr("_", "-").casecmp?(raw.tr("_", "-")) ||
        loc_s.tr("_", "-").downcase == raw.tr("_", "-").downcase
    end
  end
end
