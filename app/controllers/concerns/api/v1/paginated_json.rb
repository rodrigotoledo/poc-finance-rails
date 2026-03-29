# frozen_string_literal: true

module Api
  module V1
    # Paginação alinhada ao TanStack Table (manualPagination): +page+ (1-based), +per_page+.
    module PaginatedJson
      extend ActiveSupport::Concern

      MAX_PER_PAGE = 100

      included do
        include Pagy::Backend
      end

      private

      def paginate_collection(scope)
        per = params[:per_page].to_i
        per = Pagy::DEFAULT[:items] if per < 1
        per = [per, MAX_PER_PAGE].min
        pagy(scope, items: per)
      end

      def pagination_meta(pagy)
        {
          page: pagy.page,
          per_page: pagy.vars[:items],
          total_count: pagy.count,
          total_pages: pagy.pages
        }
      end
    end
  end
end
