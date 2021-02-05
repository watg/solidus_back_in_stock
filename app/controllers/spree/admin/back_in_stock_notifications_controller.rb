module Spree
  module Admin
    class BackInStockNotificationsController < ResourceController
      before_action :set_filter_params, only: :summary
      before_action :set_stock_locations, only: :summary
      before_action :set_back_in_stock_notifications, only: :summary

      def index
        @back_in_stock_notifications = @back_in_stock_notifications
          .pending
          .includes(:stock_location, variant: :product)
          .order(updated_at: :desc)

        respond_to do |format|
          format.html do
            @back_in_stock_notifications = @back_in_stock_notifications.page(params[:page])
          end
          format.csv do
            send_data @back_in_stock_notifications.to_csv
          end
        end
      end

      def summary
        @back_in_stock_notifications_summary = Spree::BackInStockNotification.pending
          .where(stock_location_option)
          .group(:variant).count
          .map { |v,n| [v, n] }
          .sort_by { |x| sort_value(*x) }

        @back_in_stock_notifications_summary = @back_in_stock_notifications_summary.reverse unless params[:sort_by] == "sku"
      end

      private

      def sort_value(variant, count)
        if params[:sort_by] == "sku"
          variant.sku
        else
          count
        end
      end

      def set_filter_params
        @filter_params = params.permit(:sort_by, :stock_location_id)
      end

      def stock_location_option
        @stock_location_option || params[:stock_location_id] ? {stock_location_id: params[:stock_location_id]} : {}
      end

      def set_stock_locations
        @stock_locations = Spree::StockLocation.select(:id, :name)
      end

      def set_back_in_stock_notifications
        @back_in_stock_notifications = Spree::BackInStockNotification.pending.where(stock_location_option)
      end
    end
  end
end
