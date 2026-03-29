require 'faker'

puts "Creating Originators..."
originators = []
100.times do
  originators << {
    legal_name: Faker::Company.name,
    tax_id: Faker::Company.brazilian_company_number,
    created_at: Time.current,
    updated_at: Time.current
  }
end
Originator.insert_all(originators)
originator_ids = Originator.pluck(:id)

puts "Creating Receivables..."
receivables = []
1000.times do
  originator_id = originator_ids.sample
  receivables << {
    originator_id: originator_id,
    reference_number: Faker::Alphanumeric.alphanumeric(number: 10).upcase,
    amount_cents: rand(100000..10000000), # 1000 to 100000 BRL
    due_on: Faker::Date.forward(days: 365),
    status: Receivable::STATUSES.sample,
    created_at: Time.current,
    updated_at: Time.current
  }
end
Receivable.insert_all(receivables)
receivable_ids = Receivable.pluck(:id)

puts "Creating CreditOperations..."
credit_operations = []
1000.times do
  receivable_id = receivable_ids.sample
  originator_id = Receivable.find(receivable_id).originator_id
  credit_operations << {
    receivable_id: receivable_id,
    originator_id: originator_id,
    funded_amount_cents: rand(100000..5000000), # 1000 to 50000 BRL
    rate: rand(0.01..0.10),
    status: CreditOperation::STATUSES.sample,
    created_at: Time.current,
    updated_at: Time.current
  }
end
CreditOperation.insert_all(credit_operations)
credit_operation_ids = CreditOperation.pluck(:id)

puts "Creating ImportBatches..."
import_batches = []
1000.times do
  import_batches << {
    originator_id: originator_ids.sample,
    filename: Faker::File.file_name(dir: 'imports', ext: 'csv'),
    file_path: "/tmp/#{Faker::File.file_name(ext: 'csv')}",
    file_type: ImportBatch::FILE_TYPES.sample,
    status: ImportBatch::STATUSES.sample,
    total_rows: rand(100..10000),
    processed_rows: 0,
    failed_rows: 0,
    row_errors: [],
    created_at: Time.current,
    updated_at: Time.current
  }
end
ImportBatch.insert_all(import_batches)

puts "Creating RegulatoryGaps..."
regulatory_gaps = []
1000.times do
  regulatory_gaps << {
    credit_operation_id: credit_operation_ids.sample,
    area: Faker::Lorem.word,
    status: ['open', 'closed', 'pending'].sample,
    created_at: Time.current,
    updated_at: Time.current
  }
end
Compliance::RegulatoryGap.insert_all(regulatory_gaps)

puts "Seeds completed!"