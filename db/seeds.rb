require "faker"

puts "Creating Originators..."
originator_attribute_rows = []
100.times do
  originator_attribute_rows << {
    legal_name: Faker::Company.name,
    tax_id: Faker::Company.brazilian_company_number,
    created_at: Time.current,
    updated_at: Time.current
  }
end
Originator.insert_all(originator_attribute_rows)
all_originator_primary_keys = Originator.pluck(:id)

puts "Creating Receivables..."
receivable_attribute_rows = []
1000.times do
  sampled_originator_id = all_originator_primary_keys.sample
  receivable_attribute_rows << {
    originator_id: sampled_originator_id,
    reference_number: Faker::Alphanumeric.alphanumeric(number: 10).upcase,
    amount_cents: rand(100000..10_000_000), # 1000 to 100000 BRL
    due_on: Faker::Date.forward(days: 365),
    status: Receivable::STATUSES.sample,
    created_at: Time.current,
    updated_at: Time.current
  }
end
Receivable.insert_all(receivable_attribute_rows)
all_receivable_primary_keys = Receivable.pluck(:id)

puts "Creating CreditOperations..."
credit_operation_attribute_rows = []
1000.times do
  sampled_receivable_id = all_receivable_primary_keys.sample
  originator_id_for_receivable = Receivable.find(sampled_receivable_id).originator_id
  credit_operation_attribute_rows << {
    receivable_id: sampled_receivable_id,
    originator_id: originator_id_for_receivable,
    funded_amount_cents: rand(100000..5_000_000), # 1000 to 50000 BRL
    rate: rand(0.01..0.10),
    status: CreditOperation::STATUSES.sample,
    created_at: Time.current,
    updated_at: Time.current
  }
end
CreditOperation.insert_all(credit_operation_attribute_rows)
all_credit_operation_primary_keys = CreditOperation.pluck(:id)

puts "Creating ImportBatches..."
import_batch_attribute_rows = []
1000.times do
  import_batch_attribute_rows << {
    originator_id: all_originator_primary_keys.sample,
    filename: Faker::File.file_name(dir: "imports", ext: "csv"),
    file_path: "/tmp/#{Faker::File.file_name(ext: 'csv')}",
    file_type: ImportBatch::FILE_TYPES.sample,
    status: ImportBatch::STATUSES.sample,
    total_rows: rand(100..10_000),
    processed_rows: 0,
    failed_rows: 0,
    row_errors: [],
    created_at: Time.current,
    updated_at: Time.current
  }
end
ImportBatch.insert_all(import_batch_attribute_rows)

puts "Creating RegulatoryGaps..."
regulatory_gap_attribute_rows = []
1000.times do
  regulatory_gap_attribute_rows << {
    credit_operation_id: all_credit_operation_primary_keys.sample,
    area: Faker::Lorem.word,
    status: ["open", "closed", "pending"].sample,
    created_at: Time.current,
    updated_at: Time.current
  }
end
Compliance::RegulatoryGap.insert_all(regulatory_gap_attribute_rows)

load Rails.root.join("db/seeds_investments_domain.rb")

puts "Seeds completed!"
