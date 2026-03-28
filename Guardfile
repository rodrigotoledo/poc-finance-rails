# frozen_string_literal: true

# File watching in Docker (macOS/Windows volumes): set LISTEN_GEM_POLLING=1 (see compose.yml guard service).

guard :minitest, spring: false, all_on_start: true, all_after_pass: false do
  watch(%r{^test/(.*)/?([^/]+)_test\.rb$})
  watch(%r{^test/test_helper\.rb$}) { "test" }

  watch(%r{^app/models/(.+)\.rb$}) do |m|
    path = m[1]
    "test/models/#{path}_test.rb"
  end

  watch(%r{^app/controllers/(.+)\.rb$}) do |m|
    path = m[1]
    "test/controllers/#{path}_test.rb"
  end
end
