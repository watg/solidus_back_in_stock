class AddProductIdToSpreeBackInStockNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_back_in_stock_notifications, :product_id, :integer
    add_index :spree_back_in_stock_notifications, :product_id

    # Associate any previous notification requests to the variant product
    # The column is needed to associate requests to a product kit where the variant is a component
    Spree::BackInStockNotification.includes(:variant).find_each do |bisn|
      bisn.update_column :product_id, bisn.variant.product_id
    end
  end
end
