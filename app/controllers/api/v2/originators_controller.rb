# frozen_string_literal: true

module Api
  module V2
    class OriginatorsController < BaseController
      before_action :set_originator, only: %i[show update destroy]

      ORIGINATOR_SCHEMA = {
        legal_name: Parameters.string,
        tax_id: Parameters.string
      }

      permitted_parameters :index, {}
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, originator: ORIGINATOR_SCHEMA
      permitted_parameters :update, id: Parameters.id, originator: ORIGINATOR_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      def index
        render json: Originator.kept.order(:created_at)
      end

      def show
        render json: @originator
      end

      def create
        originator = Originator.new(originator_params)
        if originator.save
          render json: originator, status: :created
        else
          render json: { errors: originator.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @originator.update(originator_params)
          render json: @originator
        else
          render json: { errors: @originator.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @originator.discard
          head :no_content
        else
          render json: { errors: @originator.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_originator
        @originator = Originator.kept.find(params[:id])
      end

      def originator_params
        params.require(:originator).permit(ORIGINATOR_SCHEMA)
      end
    end
  end
end
