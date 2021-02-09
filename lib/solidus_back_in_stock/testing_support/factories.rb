# frozen_string_literal: true

FactoryBot.define do
  factory :back_in_stock_notification, class: Spree::BackInStockNotification do
    label  { "Perfect Peach" }
    email { "christopher@woolandthegang.com" }
    country_iso { "GB" }
    locale { "en" }
    email_sent_at { nil}
    email_sent_count { 0 }

    variant { |v| v.association(:variant) }
    product { |v| v.association(:product) }
    user { |v| v.association(:user) }
    stock_location { |v| v.association(:stock_location) }
  end
end
