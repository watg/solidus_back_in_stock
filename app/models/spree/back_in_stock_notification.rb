class Spree::BackInStockNotification < ApplicationRecord
  paginates_per 50

  belongs_to :user, class_name: 'Spree::User', optional: true
  belongs_to :variant, class_name: 'Spree::Variant', optional: false
  belongs_to :stock_location, class_name: 'Spree::StockLocation', optional: false

  validates_presence_of :label, :email, :country_iso, :locale, :email_sent_count, :variant
  validates :email, 'spree/email' => true, allow_blank: true
  validates_uniqueness_of :variant, scope: [:email]

  scope :pending, -> { where(email_sent_at: nil) }

  scope :in_stock, -> (stock_location = nil) do
    joins(variant: :stock_items)
    .distinct
    .where(stock_location: stock_location)
    .where(variant: { spree_stock_items: { stock_location_id: stock_location.id }})
    .where("count_on_hand > ? OR backorderable = ?", 0, true)
  end

  def product
    variant.product
  end

  def stock_count
    sc = variant.stock_items.find_by(stock_location: stock_location)
    sc.backorderable ? '∞' : sc.count_on_hand
  end

  def pending?
    email_sent_at.nil?
  end
end
