class CreateSpreeBackInStockNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_back_in_stock_notifications do |t|
      t.string :label
      t.integer :variant_id, null: false
      t.string :email, null: false
      t.integer :user_id
      t.integer :stock_location_id, null: false
      t.string :country_iso, null: false
      t.string :locale, null: false
      t.datetime :email_sent_at
      t.integer :email_sent_count, null: false, default: 0

      t.timestamps

      t.index :variant_id
      t.index :email
      t.index :user_id
      t.index :stock_location_id
    end
  end
end
