module Spree
  class BackInStockNotificationMailer < BaseMailer
    def notification(back_in_stock_notifications)
      @back_in_stock_notifications = back_in_stock_notifications
      back_in_stock_notification = @back_in_stock_notifications.first
      @store = Spree::Store.default
      @locale = back_in_stock_notification.locale
      @email = back_in_stock_notification.email
      I18n.locale = @locale

      I18n.with_locale(@locale) do
        mail(
          body: '',
          to: @email,
          from: from_address(@store),
          subject:(subject)
        )
        set_headers
      end
    end

    def set_headers
      # override
    end

    def subject
      t("spree.back_in_stock.email.subject")
    end

    def item_data
      {
        items: back_in_stock_notification_items
      }
    end

    def merge_vars
      { 'X-MC-MergeVars' => smtp_safe_headers(item_data) }
    end

    def currency
      # override
      "USD"
    end

    private

    def back_in_stock_notification_items
      @back_in_stock_notifications.map do |bisn|
        ActionController::Base.new.render_to_string(
          partial: "spree/back_in_stock_notification_mailer/back_in_stock_item",
          locals: {
            bisn: bisn,
            product_image_link: product_image_link(bisn),
            product_link: product_link(bisn),
            currency: currency,
          }
        )
      end.join
    end

    def product_image_link(bisn)
      line_item = Spree::LineItem.new(variant: bisn.variant)
      image = WATG::Presenters::LineItem.new(line_item).image
      "https:#{image&.attachment(:product)}"
    end

    def product_link(bisn)
      "#{Rails.configuration.action_mailer.default_url_options[:host]}/products/#{bisn.product.slug}"
    end
  end
end
