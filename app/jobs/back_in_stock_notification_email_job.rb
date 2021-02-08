class BackInStockNotificationEmailJob < ApplicationJob

  # stock_location_params could be {name: "Main Warehouse"} or {id: 1} or left empty to select all
  def perform(stock_location_params: {})
    @stock_location_params = stock_location_params.slice(:id, :name)

    stock_locations.each do |stock_location|
      emails_of_ready_to_send(stock_location).each do |email|
        BackInStockNotificationMailerJob.perform_later(email: email, stock_location: stock_location)
      end
    end
  end

  private

  def stock_locations
    Spree::StockLocation.where(@stock_location_params)
  end

  def emails_of_ready_to_send(stock_location)
    Spree::BackInStockNotification.emails_of_ready_to_send(stock_location)
  end
end
