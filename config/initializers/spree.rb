# frozen_string_literal: true

Spree::Backend::Config.configure do |config|
  config.menu_items << config.class::MenuItem.new(
    [':back_in_stock'],
    'bell',
    label: :back_in_stock,
    url: '/en/admin/back_in_stock_notifications/summary',
    condition: -> { can?(:admin, Spree::BackInStockNotification) }
  )
end
