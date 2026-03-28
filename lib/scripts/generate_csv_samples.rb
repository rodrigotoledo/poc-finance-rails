# :nocov:
# !/usr/bin/env ruby
# frozen_string_literal: true

# Standalone script — requires only Ruby stdlib (no Gemfile).
# Run directly: ruby lib/scripts/generate_csv_samples.rb
#
# Generates lib/samples/receivables_batch_{1..5}.csv
# Each file has 10 000 rows: ~90-97 % valid + intentional errors per batch.

require "csv"
require "date"
require "fileutils"

ORIGINATOR_TAX_IDS = %w[
  12345678000195
  98765432000198
  11223344000177
  55667788000133
  99887766000111
].freeze

VALID_STATUSES   = %w[pending eligible advanced cancelled].freeze
INVALID_STATUSES = %w[processing error submitted unknown].freeze
HEADERS          = %w[originator_tax_id reference_number amount due_on status].freeze
TOTAL_ROWS       = 10_000
OUTPUT_DIR       = File.expand_path("../../samples", __FILE__)

def valid_row(seq, batch_num)
  tax_id = ORIGINATOR_TAX_IDS[seq % ORIGINATOR_TAX_IDS.size]
  ref    = "RECV-#{2025 + batch_num}-#{seq.to_s.rjust(6, '0')}"
  amount = format("%.2f", rand(100.0..50_000.0))
  due_on = (Date.today + rand(30..730)).iso8601
  status = VALID_STATUSES.sample
  [ tax_id, ref, amount, due_on, status ]
end

def error_row(seq, batch_num)
  tax_id = ORIGINATOR_TAX_IDS[seq % ORIGINATOR_TAX_IDS.size]
  ref    = "RECV-#{2025 + batch_num}-#{seq.to_s.rjust(6, '0')}"
  amount = format("%.2f", rand(100.0..50_000.0))
  due_on = (Date.today + rand(30..730)).iso8601
  status = VALID_STATUSES.sample

  case batch_num
  when 1
    [ tax_id, ref, amount, due_on, INVALID_STATUSES.sample ]
  when 2
    if seq.even?
      [ tax_id, ref, nil, due_on, status ]
    else
      [ tax_id, ref, amount, "32/13/2025", status ]
    end
  when 3
    [ tax_id, nil, amount, due_on, status ]
  when 4
    if seq.even?
      [ tax_id, ref, "-#{amount}", due_on, status ]
    else
      [ tax_id, ref, "N/A", due_on, status ]
    end
  when 5
    if seq % 3 == 0
      [ nil, nil, nil, nil, nil ]
    else
      [ "00000000000000", ref, amount, due_on, status ]
    end
  end
end

ERROR_RATES = { 1 => 0.05, 2 => 0.10, 3 => 0.03, 4 => 0.15, 5 => 0.05 }.freeze

FileUtils.mkdir_p(OUTPUT_DIR)

5.times do |i|
  batch_num  = i + 1
  error_rate = ERROR_RATES[batch_num]
  path       = File.join(OUTPUT_DIR, "receivables_batch_#{batch_num}.csv")
  valid      = 0
  invalid    = 0

  CSV.open(path, "w") do |csv|
    csv << HEADERS
    TOTAL_ROWS.times do |j|
      seq = batch_num * TOTAL_ROWS + j + 1
      if rand < error_rate
        csv << error_row(seq, batch_num)
        invalid += 1
      else
        csv << valid_row(seq, batch_num)
        valid += 1
      end
    end
  end

  size_kb = (File.size(path) / 1024.0).round(1)
  puts "  Batch #{batch_num}: #{valid} valid + #{invalid} invalid  =>  #{File.basename(path)}  (#{size_kb} KB)"
end

puts "\nDone. CSV files written to #{OUTPUT_DIR}"
# :nocov:
