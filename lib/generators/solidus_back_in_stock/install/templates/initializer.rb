# frozen_string_literal: true

SolidusBackInStock.configure do |config|
  # The stock level must be greater than this threshold before back in stock notifications are sent.
  # You may like to set a higher threshold than this to avoid notifications being sent to many
  # customers when a single item is returned.
  config.back_in_stock_threshold = 0
end
