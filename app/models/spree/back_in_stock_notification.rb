require 'csv'

class Spree::BackInStockNotification < ApplicationRecord
  paginates_per 50

  belongs_to :user, class_name: 'Spree::User', optional: true
  belongs_to :variant, class_name: 'Spree::Variant', optional: false
  belongs_to :product, class_name: 'Spree::Product', optional: false
  belongs_to :stock_location, class_name: 'Spree::StockLocation', optional: false

  validates_presence_of :label, :email, :country_iso, :locale, :email_sent_count, :variant
  validates :email, 'spree/email' => true, allow_blank: true
  validates_uniqueness_of :variant, scope: [:email]

  before_validation do
    self.product_id ||= variant.product_id
  end

  scope :pending, -> { where(email_sent_at: nil) }

  scope :in_stock, -> (stock_location) do
    available_variants = joins(variant: [:stock_items, :product])
      .where(stock_location: stock_location)
      .where(spree_stock_items: {stock_location_id: stock_location.id })
      .merge(Spree::Product.available)
      .distinct

    available_variants
      .where("spree_stock_items.count_on_hand > ? OR spree_stock_items.backorderable = ?", 0, true)
      .or(available_variants.where(spree_variants: {track_inventory: false}))
  end

  scope :ready_to_send_by_email, -> (email, stock_location) do
    pending
      .where(email: email, stock_location: stock_location)
      .in_stock(stock_location)
  end

  def self.emails_of_ready_to_send(stock_location)
    pending.in_stock(stock_location).pluck(:email)
  end

  def stock_count
    sc = variant.stock_items.find_by(stock_location: stock_location)
    sc.backorderable ? '∞' : sc.count_on_hand
  end

  def pending?
    email_sent_at.nil?
  end

  def product_name
    [variant.product.name, product.name].uniq.join(" - ")
  end

  def kit?
    product_id != variant.product_id
  end

  def self.to_csv
    CSV.generate do |csv|
      csv << [
        "id",
        "product",
        "label",
        "product_sku",
        "variant_sku",
        "stock_location",
        "country_iso",
        "locale",
        "email_sent_count",
      ]

      pending.each do |bisn|
        back_in_stock_notification_values = []
        back_in_stock_notification_values << bisn.id
        back_in_stock_notification_values << bisn.product_name
        back_in_stock_notification_values << bisn.label
        back_in_stock_notification_values << bisn.product.sku
        back_in_stock_notification_values << bisn.variant.sku
        back_in_stock_notification_values << bisn.stock_location.name
        back_in_stock_notification_values << bisn.country_iso
        back_in_stock_notification_values << bisn.locale
        back_in_stock_notification_values << bisn.email_sent_count
        csv << back_in_stock_notification_values
      end
    end
  end
end
