class BackInStockNotificationMailerJob < ApplicationJob

  def perform(email:, stock_location:)
    user_bisns = Spree::BackInStockNotification.ready_to_send_by_email(email, stock_location)
    return unless user_bisns.present?

    Spree::BackInStockNotificationMailer.notification(user_bisns).deliver_now

    user_bisns.each do |bisn|
      bisn.email_sent_at = Time.current
      bisn.email_sent_count += 1
      bisn.save!
    end
  end
end
