module Spree
  class BackInStockNotificationsController < StoreController

    def create
      @back_in_stock_notification = Spree::BackInStockNotification
        .where(back_in_stock_notification_params.slice(:email, :variant_id, :product_id))
        .where.not(email_sent_at: nil)
        .first_or_initialize(options)

      @back_in_stock_notification.label = back_in_stock_notification_params[:label]
      @back_in_stock_notification.email_sent_at = nil
      @back_in_stock_notification.save
    end

    private

    def back_in_stock_notification_params
      @back_in_stock_notification_params ||= params
        .require(:back_in_stock_notification)
        .permit(:label, :variant_id, :product_id, :locale, :country_iso, :email, :user_id)
    end

    def options
      {
        user_id: current_spree_user&.id,
        locale: session[:locale],
        country_iso: session[:country_iso],
        stock_location_id: session[:stock_location_id],
      }
    end
  end
end
