# :nocov:
require "csv"

# Usage:
#   bundle exec rake samples:generate
#
# Creates lib/samples/receivables_batch_{1..5}.csv  (10 000 rows each)
#         lib/samples/receivables_batch_{1..5}.xlsx (10 000 rows each)
#
# Each file has a mix of valid rows and intentional errors to exercise
# the import pipeline: invalid status, negative amounts, missing fields,
# bad dates, and unknown originator tax IDs.

namespace :samples do
  # These CNPJs must exist in your DB (seed them first or use the fixtures).
  SAMPLE_ORIGINATOR_TAX_IDS = %w[
    12345678000195
    98765432000198
    11223344000177
    55667788000133
    99887766000111
  ].freeze

  VALID_STATUSES   = %w[pending eligible advanced cancelled].freeze
  INVALID_STATUSES = %w[processing error submitted unknown].freeze

  TOTAL_ROWS  = 10_000
  OUTPUT_DIR  = Rails.root.join("lib", "samples")

  # ---------------------------------------------------------------------------
  # CSV generation
  # ---------------------------------------------------------------------------
  desc "Generate 5 CSV + 5 XLSX sample receivable files (10 000 rows each) in lib/samples/"
  task generate: :environment do
    FileUtils.mkdir_p(OUTPUT_DIR)

    5.times do |i|
      batch_num = i + 1

      csv_path  = OUTPUT_DIR.join("receivables_batch_#{batch_num}.csv")
      xlsx_path = OUTPUT_DIR.join("receivables_batch_#{batch_num}.xlsx")

      rows = build_rows(batch_num)

      write_csv(csv_path,  rows)
      write_xlsx(xlsx_path, rows)

      valid   = rows.count { |r| r[:_valid] }
      invalid = rows.size - valid
      puts "Batch #{batch_num}: #{rows.size} rows (#{valid} valid, #{invalid} invalid)  →  #{csv_path.basename}  +  #{xlsx_path.basename}"
    end

    puts "\nDone. Files written to #{OUTPUT_DIR}"
  end

  # ---------------------------------------------------------------------------
  # Row builders — each batch has a different error pattern
  # ---------------------------------------------------------------------------
  def build_rows(batch_num)
    rows = []

    TOTAL_ROWS.times do |i|
      seq        = batch_num * TOTAL_ROWS + i + 1
      tax_id     = SAMPLE_ORIGINATOR_TAX_IDS[i % SAMPLE_ORIGINATOR_TAX_IDS.size]
      ref        = "RECV-#{2025 + batch_num}-#{"%.6d" % seq}"
      amount     = format("%.2f", rand(100.0..50_000.0))
      due_on     = (Date.today + rand(30..730)).iso8601
      status     = VALID_STATUSES.sample

      error_rate = case batch_num
      when 1 then 0.05  # 5 %  – invalid status
      when 2 then 0.10  # 10 % – missing amount / bad date
      when 3 then 0.03  # 3 %  – missing reference_number
      when 4 then 0.15  # 15 % – negative / non-numeric amount
      when 5 then 0.05  # 5 %  – unknown originator or blank row
      end

      row = if rand < error_rate
        inject_error(batch_num, seq, tax_id, ref, amount, due_on, status)
      else
        valid_row(tax_id, ref, amount, due_on, status)
      end

      rows << row
    end

    rows
  end

  def valid_row(tax_id, ref, amount, due_on, status)
    { originator_tax_id: tax_id, reference_number: ref,
      amount: amount, due_on: due_on, status: status, _valid: true }
  end

  def inject_error(batch_num, seq, tax_id, ref, amount, due_on, status)
    case batch_num
    when 1
      # Invalid status value
      { originator_tax_id: tax_id, reference_number: ref,
        amount: amount, due_on: due_on, status: INVALID_STATUSES.sample, _valid: false }
    when 2
      if seq.even?
        # Missing amount
        { originator_tax_id: tax_id, reference_number: ref,
          amount: nil, due_on: due_on, status: status, _valid: false }
      else
        # Malformed date
        { originator_tax_id: tax_id, reference_number: ref,
          amount: amount, due_on: "32/13/2025", status: status, _valid: false }
      end
    when 3
      # Missing reference_number
      { originator_tax_id: tax_id, reference_number: nil,
        amount: amount, due_on: due_on, status: status, _valid: false }
    when 4
      if seq.even?
        # Negative amount
        { originator_tax_id: tax_id, reference_number: ref,
          amount: "-#{amount}", due_on: due_on, status: status, _valid: false }
      else
        # Non-numeric amount
        { originator_tax_id: tax_id, reference_number: ref,
          amount: "N/A", due_on: due_on, status: status, _valid: false }
      end
    when 5
      if seq % 3 == 0
        # Completely blank row
        { originator_tax_id: nil, reference_number: nil,
          amount: nil, due_on: nil, status: nil, _valid: false }
      else
        # Unknown originator tax_id
        { originator_tax_id: "00000000000000", reference_number: ref,
          amount: amount, due_on: due_on, status: status, _valid: false }
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Writers
  # ---------------------------------------------------------------------------
  HEADERS = %w[originator_tax_id reference_number amount due_on status].freeze

  def write_csv(path, rows)
    CSV.open(path, "w") do |csv|
      csv << HEADERS
      rows.each do |row|
        csv << HEADERS.map { |h| row[h.to_sym] }
      end
    end
  end

  def write_xlsx(path, rows)
    package = Axlsx::Package.new
    sheet   = package.workbook.add_worksheet(name: "Receivables")

    header_style = package.workbook.styles.add_style(
      b: true, bg_color: "1F4E79", fg_color: "FFFFFF", alignment: { horizontal: :center }
    )

    sheet.add_row(HEADERS, style: header_style)

    rows.each do |row|
      sheet.add_row HEADERS.map { |h| row[h.to_sym].to_s }
    end

    package.serialize(path.to_s)
  end
end
# :nocov:
