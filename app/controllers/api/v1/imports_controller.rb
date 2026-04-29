module Api
  module V1
    class ImportsController < BaseController
      ALLOWED_EXTENSIONS = %w[.csv .xlsx].freeze

      # GET /api/v1/imports
      def index
        scope = ImportBatch.order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where("filename ILIKE :q", q: "%#{params[:q].to_s.strip}%") if params[:q].present?
        pagy, records = paginate_collection(scope)
        data = records.map { |b| serialize(b) }
        render json: { data: data, meta: pagination_meta(pagy) }
      end

      # GET /api/v1/imports/:id
      def show
        render json: serialize(batch)
      end

      # POST /api/v1/imports
      # Params:
      #   file         — multipart file (required)
      #   originator_id — optional; used when rows don't carry originator_tax_id
      def create
        unless params[:file].present?
          return render json: { error: t("imports.file_required") }, status: :unprocessable_entity
        end

        ext = File.extname(params[:file].original_filename).downcase
        unless ALLOWED_EXTENSIONS.include?(ext)
          return render json: { error: t("imports.unsupported_format") }, status: :unprocessable_entity
        end

        file_type = ext.delete(".")
        file_path = persist_upload(params[:file], file_type)

        import_batch = ImportBatch.new(
          originator_id: params[:originator_id],
          filename:      params[:file].original_filename,
          file_path:     file_path,
          file_type:     file_type
        )
        apply_idempotency_key(import_batch)
        import_batch.save!

        ProcessImportFileJob.perform_async(import_batch.id)

        render json: serialize(import_batch), status: :created
      rescue ActiveRecord::RecordNotUnique
        existing = ImportBatch.find_by(idempotency_key: idempotency_key)
        raise if existing.blank?

        render json: serialize(existing), status: :ok
      end

      private

      def batch
        @batch ||= ImportBatch.find(params[:id])
      end

      def persist_upload(file, file_type)
        dir = Rails.root.join("tmp", "imports")
        FileUtils.mkdir_p(dir)
        path = dir.join("#{SecureRandom.uuid}.#{file_type}").to_s
        File.open(path, "wb") { |f| f.write(file.read) }
        path
      end

      def serialize(import_batch)
        {
          id:             import_batch.id,
          filename:       import_batch.filename,
          file_type:      import_batch.file_type,
          originator_id:  import_batch.originator_id,
          status:         import_batch.status,
          total_rows:     import_batch.total_rows,
          processed_rows: import_batch.processed_rows,
          failed_rows:    import_batch.failed_rows,
          error_sample:   import_batch.row_errors.first(10),
          created_at:     import_batch.created_at,
          updated_at:     import_batch.updated_at
        }
      end
    end
  end
end
