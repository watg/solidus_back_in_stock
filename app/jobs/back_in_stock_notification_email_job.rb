class BackInStockNotificationEmailJob < ApplicationJob

  # stock_location_params could be {name: "Main Warehouse"} or {id: 1} or left empty to select all
  def perform(stock_location_params: {})
    @stock_location_params = stock_location_params.slice(:id, :name)

    send_back_in_stock_notifications
  end

  private

  def send_back_in_stock_notifications
    in_stock_user_notifications.each do |email, user_bisns|
      Spree::BackInStockNotificationMailer.notification(user_bisns).deliver_now

      user_bisns.each do |bisn|
        bisn.email_sent_at = Time.current
        bisn.email_sent_count += 1
        bisn.save!
      end
    end
  end

  def in_stock_user_notifications
    # notifications for items back in stock and grouped by email
    Spree::StockLocation.where(@stock_location_params).inject([]) { |sum, stock_location|
      sum += Spree::BackInStockNotification.pending.in_stock(stock_location)
    }.uniq.group_by(&:email)
  end
end
