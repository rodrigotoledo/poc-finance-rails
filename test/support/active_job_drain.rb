# frozen_string_literal: true

# Active Job test adapter flushes only jobs present at the start of each
# `perform_enqueued_jobs` call. Chains like `ProcessImportFileJob` → `ImportChunkJob`
# need multiple passes (see flush_enqueued_jobs in active_job/test_helper.rb).
module ActiveJobDrain
  def drain_enqueued_jobs
    return unless defined?(enqueued_jobs)

    10.times do
      break if enqueued_jobs.empty?

      perform_enqueued_jobs
    end
  end
end
