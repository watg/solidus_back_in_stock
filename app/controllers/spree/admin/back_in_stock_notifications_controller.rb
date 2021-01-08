module Spree
  module Admin
    class BackInStockNotificationsController < ResourceController

      def index
        @back_in_stock_notifications = @back_in_stock_notifications
          .order(updated_at: :desc)
          .page params[:page]
          # .pending
      end
    end
  end
end
