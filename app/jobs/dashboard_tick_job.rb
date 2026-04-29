# frozen_string_literal: true

class DashboardTickJob
  include Sidekiq::Worker

  sidekiq_options(
    queue: :default,
    lock: :until_executed,
    lock_ttl: 10,
    on_conflict: :log
  )

  def perform
    return unless enabled?

    originator = pick_or_create_originator!
    receivable = create_receivable_for!(originator)

    create_credit_operation_for!(originator, receivable) if rand < 0.8
    maybe_create_regulatory_gap!
  end

  private

  def enabled?
    ENV.fetch("DASHBOARD_TICK_ENABLED", "1") == "1"
  end

  def pick_or_create_originator!
    Originator.kept.order(Arel.sql("RANDOM()")).first || Originator.create!(
      legal_name: Faker::Company.name,
      tax_id: Faker::Company.unique.brazilian_company_number
    )
  end

  def create_receivable_for!(originator)
    Receivable.create!(
      originator: originator,
      reference_number: Faker::Number.unique.number(digits: 10).to_s,
      amount_cents: rand(50_00..500_000),
      due_on: Date.current + rand(5..90).days,
      status: Receivable::STATUSES.sample
    )
  end

  def create_credit_operation_for!(originator, receivable)
    CreditOperation.create!(
      originator: originator,
      receivable: receivable,
      funded_amount_cents: rand(10_00..receivable.amount_cents),
      rate: (rand * 5.0).round(4),
      status: CreditOperation::STATUSES.sample
    )
  end

  def maybe_create_regulatory_gap!
    return if rand >= 0.25

    Compliance::RegulatoryGap.create!(
      credit_operation: CreditOperation.kept.order(Arel.sql("RANDOM()")).first,
      area: Faker::Commerce.department(max: 2),
      status: %w[open resolved dismissed].sample
    )
  end
end
