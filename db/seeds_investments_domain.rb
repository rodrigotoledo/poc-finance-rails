# frozen_string_literal: true

# Dados de exemplo para tudo o que a migration `20260331120000_investments_funds_risks_domain`
# criou ou alterou: investors, funds, investment_accounts, investments, financial_assets,
# investment_risks, risk_assessments + colunas em receivables e credit_operations.
#
# Idempotente: se já existir pelo menos um investor, não volta a inserir (evita violar unicidade).
# Para reexecutar: truncar tabelas dependentes ou apagar investors e correr de novo.
#
# Consola Docker (exemplo):
#   docker compose exec app bin/rails runner "load Rails.root.join('db/seeds_investments_domain.rb')"
# ou:
#   docker compose exec app bin/rails db:seed

return if Investor.exists?

puts "Seeding investments domain (funds, investors, accounts, investments, assets, risks)..."

timestamp_now = Time.current
reference_date = Date.current

# --- Investors (Publishable + tax_id único) ---
investor_attribute_rows = 30.times.map do |investor_index|
  {
    legal_name: "Investidor Seed #{investor_index + 1} #{Faker::Company.name}",
    tax_id: format("%014d", 7_000_000_000_000 + investor_index),
    investor_type: Investor::INVESTOR_TYPES.sample,
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
end
Investor.insert_all(investor_attribute_rows)
seed_investors = Investor.order(:id).to_a

# --- Funds ---
fund_attribute_rows = [
  {
    name: "Fundo Recebíveis Alpha",
    fund_type: "debt",
    total_commitment_cents: 500_000_000_000,
    allocated_amount_cents: 0,
    available_amount_cents: 500_000_000_000,
    inception_date: reference_date - 365,
    maturity_date: reference_date + 365 * 5,
    target_return_rate: 12.5,
    status: "active",
    created_at: timestamp_now,
    updated_at: timestamp_now
  },
  {
    name: "Fundo Crédito Privado Beta",
    fund_type: "mixed",
    total_commitment_cents: 200_000_000_000,
    allocated_amount_cents: 0,
    available_amount_cents: 200_000_000_000,
    inception_date: reference_date - 180,
    maturity_date: reference_date + 365 * 3,
    target_return_rate: 10.0,
    status: "active",
    created_at: timestamp_now,
    updated_at: timestamp_now
  },
  {
    name: "Fundo Equity Gamma",
    fund_type: "equity",
    total_commitment_cents: 80_000_000_000,
    allocated_amount_cents: 0,
    available_amount_cents: 80_000_000_000,
    inception_date: reference_date - 90,
    maturity_date: nil,
    target_return_rate: 15.0,
    status: "active",
    created_at: timestamp_now,
    updated_at: timestamp_now
  },
  {
    name: "Fundo Liquidando Delta",
    fund_type: "debt",
    total_commitment_cents: 10_000_000_000,
    allocated_amount_cents: 9_500_000_000,
    available_amount_cents: 500_000_000,
    inception_date: reference_date - 700,
    maturity_date: reference_date + 30,
    target_return_rate: 8.0,
    status: "winding_up",
    created_at: timestamp_now,
    updated_at: timestamp_now
  },
  {
    name: "Fundo Encerrado Épsilon",
    fund_type: "other",
    total_commitment_cents: 5_000_000_000,
    allocated_amount_cents: 5_000_000_000,
    available_amount_cents: 0,
    inception_date: reference_date - 1000,
    maturity_date: reference_date - 30,
    target_return_rate: 7.5,
    status: "closed",
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
]
Fund.insert_all(fund_attribute_rows)
seed_funds = Fund.order(:id).to_a
seed_fund_primary_keys = seed_funds.map(&:id)

# --- Investment accounts (account_number único) ---
all_originator_primary_keys = Originator.pluck(:id)
investment_account_attribute_rows = []
seed_investors.each_with_index do |investor, investor_index|
  investment_account_attribute_rows << {
    investor_id: investor.id,
    originator_id: all_originator_primary_keys.sample,
    account_number: format("IA-%s-%04d", investor.tax_id.last(6), investor_index * 2 + 1),
    available_balance_cents: rand(5_000_000..50_000_000),
    invested_balance_cents: 0,
    status: "active",
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
  investment_account_attribute_rows << {
    investor_id: investor.id,
    originator_id: nil,
    account_number: format("IA-%s-%04d", investor.tax_id.last(6), investor_index * 2 + 2),
    available_balance_cents: rand(1_000_000..20_000_000),
    invested_balance_cents: 0,
    status: %w[active suspended].sample,
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
end
InvestmentAccount.insert_all(investment_account_attribute_rows)
investment_accounts_grouped_by_investor_id = InvestmentAccount.group_by(&:investor_id)

# --- Receivables: colunas collateral / discount / risk_weight ---
Receivable.find_in_batches(batch_size: 250) do |receivable_batch|
  receivable_batch.each do |receivable|
    receivable.update_columns(
      collateral_value_cents: (receivable.amount_cents * (1.0 + rand * 0.3)).to_i,
      discount_rate: rand(0.01..0.12).round(4),
      risk_weight: rand(0.5..2.5).round(2)
    )
  end
end

# --- Credit operations: colunas de investimento / risco ---
CreditOperation.find_each do |credit_operation|
  credit_operation.update_columns(
    investment_start_date: reference_date - rand(30..180),
    investment_end_date: reference_date + rand(90..540),
    risk_rating: %w[AAA AA A BBB BB B].sample,
    expected_return_rate: (credit_operation.rate.to_d + rand(0.005..0.03)).round(4),
    total_invested_cents: 0,
    available_for_investment_cents: (credit_operation.funded_amount_cents * rand(0.2..0.8)).to_i
  )
end

# --- Investments (investidor alinhado à conta; amount > 0) ---
credit_operations_for_investment_seeds =
  CreditOperation.includes(:receivable, :originator).order(:id).limit(200).to_a
investment_attribute_rows = []
credit_operations_for_investment_seeds.each_with_index do |credit_operation, credit_operation_index|
  investor = seed_investors[credit_operation_index % seed_investors.size]
  investment_account = investment_accounts_grouped_by_investor_id[investor.id]&.first
  next unless investment_account

  optional_fund_primary_key = (credit_operation_index % 7).zero? ? nil : seed_fund_primary_keys.sample
  funded_share = [0.05, 0.08, 0.1, 0.12, 0.15].sample
  investment_amount_cents =
    (credit_operation.funded_amount_cents * funded_share).to_i.clamp(10_000, credit_operation.funded_amount_cents)

  investment_attribute_rows << {
    investor_id: investor.id,
    fund_id: optional_fund_primary_key,
    credit_operation_id: credit_operation.id,
    investment_account_id: investment_account.id,
    amount_cents: investment_amount_cents,
    interest_rate: rand(0.08..0.18).round(4),
    investment_date: reference_date - rand(10..120),
    maturity_date: reference_date + rand(60..400),
    status: Investment::STATUSES.sample,
    discarded_at: nil,
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
end
Investment.insert_all(investment_attribute_rows)

# Atualiza totais na operação e saldos de conta / alocação em fundos
Investment.includes(:credit_operation, :fund, :investment_account).find_each do |investment|
  credit_operation = investment.credit_operation
  credit_operation.increment!(:total_invested_cents, investment.amount_cents)

  investment_account = investment.investment_account
  investment_account.reload
  investment_account.update_columns(
    invested_balance_cents: investment_account.invested_balance_cents + investment.amount_cents,
    available_balance_cents: [investment_account.available_balance_cents - investment.amount_cents, 0].max
  )

  next if investment.fund_id.blank?

  fund = investment.fund
  fund.reload
  updated_available_amount_cents =
    if fund.available_amount_cents.nil?
      nil
    else
      [fund.available_amount_cents - investment.amount_cents, 0].max
    end
  fund.update_columns(
    allocated_amount_cents: fund.allocated_amount_cents + investment.amount_cents,
    available_amount_cents: updated_available_amount_cents
  )
end

CreditOperation.find_each do |credit_operation|
  remaining_capacity_cents = credit_operation.funded_amount_cents - credit_operation.total_invested_cents
  credit_operation.update_columns(available_for_investment_cents: [remaining_capacity_cents, 0].max)
end

# --- Financial assets (ligados a operação / recebível / originador) ---
financial_asset_attribute_rows = credit_operations_for_investment_seeds.first(80).map do |credit_operation|
  {
    originator_id: credit_operation.originator_id,
    credit_operation_id: credit_operation.id,
    receivable_id: credit_operation.receivable_id,
    asset_type: FinancialAsset::ASSET_TYPES.sample,
    value_cents: credit_operation.funded_amount_cents,
    book_value_cents: (credit_operation.funded_amount_cents * 0.95).to_i,
    market_value_cents: (credit_operation.funded_amount_cents * 1.02).to_i,
    liquidation_value_cents: (credit_operation.funded_amount_cents * 0.9).to_i,
    valuation_metadata: { "source" => "seed", "method" => "mark_to_model" },
    valuation_date: reference_date - rand(1..30),
    status: FinancialAsset::STATUSES.sample,
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
end
FinancialAsset.insert_all(financial_asset_attribute_rows)

# --- Investment risks ---
investments_for_risk_seed_rows = Investment.order(:id).limit(120)
investment_risk_attribute_rows = []
investments_for_risk_seed_rows.each_with_index do |investment, investment_risk_row_index|
  investment_risk_attribute_rows << {
    investment_id: investment.id,
    credit_operation_id: investment.credit_operation_id,
    risk_type: InvestmentRisk::RISK_TYPES.sample,
    probability: rand(5.0..45.0).round(2),
    impact_cents: rand(50_000..5_000_000),
    risk_score: rand(10.0..90.0).round(2),
    risk_metrics: { "var_95" => rand, "stress" => "seed" },
    assessment_date: reference_date - rand(0..60),
    mitigation_status: InvestmentRisk::MITIGATION_STATUSES.sample,
    mitigation_actions:
      investment_risk_row_index.even? ? "Monitorar covenants trimestralmente." : nil,
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
end
# Alguns riscos só a nível de operação (sem investment)
credit_operations_for_investment_seeds.first(40).each do |credit_operation|
  investment_risk_attribute_rows << {
    investment_id: nil,
    credit_operation_id: credit_operation.id,
    risk_type: "credit",
    probability: rand(10.0..35.0).round(2),
    impact_cents: rand(100_000..10_000_000),
    risk_score: rand(20.0..70.0).round(2),
    risk_metrics: {},
    assessment_date: reference_date - rand(0..45),
    mitigation_status: "pending",
    mitigation_actions: nil,
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
end
InvestmentRisk.insert_all(investment_risk_attribute_rows)

# --- Risk assessments ---
risk_assessment_attribute_rows = []
Originator.limit(40).each do |originator|
  risk_assessment_attribute_rows << {
    credit_operation_id: nil,
    originator_id: originator.id,
    assessment_type: RiskAssessment::ASSESSMENT_TYPES.sample,
    score: rand(40.0..95.0).round(2),
    rating: %w[AAA AA A BBB BB].sample,
    assessment_details: { "analyst" => "seed", "peer_group" => "fintech" },
    assessment_date: reference_date - rand(0..90),
    expiry_date: reference_date + rand(180..720),
    status: RiskAssessment::STATUSES.sample,
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
end
credit_operations_for_investment_seeds.first(60).each do |credit_operation|
  risk_assessment_attribute_rows << {
    credit_operation_id: credit_operation.id,
    originator_id: credit_operation.originator_id,
    assessment_type: "credit_risk",
    score: rand(50.0..90.0).round(2),
    rating: %w[A BBB BB B].sample,
    assessment_details: { "ltv" => rand(0.4..0.8).round(2) },
    assessment_date: reference_date - rand(0..30),
    expiry_date: reference_date + 365,
    status: "valid",
    created_at: timestamp_now,
    updated_at: timestamp_now
  }
end
RiskAssessment.insert_all(risk_assessment_attribute_rows)

puts "Investments domain seeds done (#{Investor.count} investors, #{Fund.count} funds, #{InvestmentAccount.count} accounts, #{Investment.count} investments)."
