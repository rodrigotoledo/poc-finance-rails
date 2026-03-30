# frozen_string_literal: true

module Api
  module V2
    class DashboardController < BaseController
      include ActionController::Live

      # GET /api/v2/dashboard
      def stats
        receivables = Receivable.kept
        credit_ops  = CreditOperation.kept

        render json: {
          originators: {
            total: Originator.kept.count
          },
          receivables: {
            total:             receivables.count,
            total_amount_cents: receivables.sum(:amount_cents),
            by_status:         receivables.group(:status).count
          },
          credit_operations: {
            total:             credit_ops.count,
            total_funded_cents: credit_ops.sum(:funded_amount_cents),
            avg_rate:          credit_ops.average(:rate)&.round(4).to_s,
            by_status:         credit_ops.group(:status).count
          },
          regulatory_gaps: {
            total: Compliance::RegulatoryGap.kept.count,
            open:  Compliance::RegulatoryGap.kept.where(status: "open").count
          },
          imports: {
            total:      ImportBatch.count,
            pending:    ImportBatch.where(status: "pending").count,
            processing: ImportBatch.where(status: "processing").count,
            completed:  ImportBatch.where(status: "completed").count,
            failed:     ImportBatch.where(status: "failed").count
          }
        }
      end

      # GET /api/v2/events — Server-Sent Events stream from Redis pub/sub
      def events
        response.headers["Content-Type"]      = "text/event-stream"
        response.headers["Cache-Control"]     = "no-cache"
        response.headers["X-Accel-Buffering"] = "no"
        response.headers["Access-Control-Allow-Origin"] = "*"

        redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

        # Send a heartbeat immediately so the client knows the connection is alive
        response.stream.write(": heartbeat\n\n")

        redis.subscribe("poc:events") do |on|
          on.message do |_channel, message|
            response.stream.write("data: #{message}\n\n")
          end
        end
      rescue IOError, ActionController::Live::ClientDisconnected
        # client disconnected — normal teardown
      ensure
        redis&.disconnect!
        response.stream.close
      end
    end
  end
end
