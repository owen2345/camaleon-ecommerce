Rails.application.config.to_prepare do
  CamaleonCms::Site.class_eval do
    #attr_accessible :my_id
    has_many :carts, :class_name => "Plugins::Ecommerce::Cart", foreign_key: :site_id, dependent: :destroy
    has_many :orders, :class_name => "Plugins::Ecommerce::Order", foreign_key: :site_id, dependent: :destroy
    has_many :payment_methods, :class_name => "Plugins::Ecommerce::PaymentMethod", foreign_key: :parent_id, dependent: :destroy
    has_many :shipping_methods, :class_name => "Plugins::Ecommerce::ShippingMethod", foreign_key: :parent_id, dependent: :destroy
    has_many :coupons, :class_name => "Plugins::Ecommerce::Coupon", foreign_key: :parent_id, dependent: :destroy
    has_many :tax_rates, :class_name => "Plugins::Ecommerce::TaxRate", foreign_key: :parent_id, dependent: :destroy
    has_many :product_attributes, :class_name => "Plugins::Ecommerce::Attribute", foreign_key: :site_id, dependent: :destroy

    # return all the products for current site
    def products
      post_types.where(slug: 'commerce').first.try(:posts)
    end

    # return the payment (PaymentMethod) method with type = type
    def payment_method(type)
      payment_method = payment_methods.actives.detect do |payment_method|
        payment_method.get_option('type') == type
      end
      if payment_method.nil?
        raise ArgumentError, "Payment method #{type} is not found"
      end
      payment_method
    end

    # return the invoice number to start
    def e_invoice_number_from
      (e_settings[:invoice_number_from] || 1000000000).to_s.to_i
    end

    # return the invoice number to end
    def e_invoice_number_to
      (e_settings[:invoice_number_to] || 9999999999).to_s.to_i
    end

    # set a new value for of a ecommerce setting
    def e_set_setting(key, value)
      set_option(key, value, '_setting_ecommerce')
    end

    # return the settings for ecommerce
    def e_settings(new_settings = nil)
      set_meta('_setting_ecommerce', new_settings) if new_settings.present?
      get_meta("_setting_ecommerce", {})
    end

    # return the email template for ecommerce events
    def e_email_for(key = 'email_order_paid')
      (e_settings[key]) || case key.to_s
                                  when 'email_order_received'
                                    '<h1>ORDER SUMMARY {number}</h1> Dear {name}, please review and retain the following order information for your records.<br>{order_table}'
                                  when 'email_order_confirmed'
                                    '<h1>ORDER CONFIRMED {number}</h1> Dear {name}, your order has been confirmed. Please retain the following order information for your records<br>{order_table}'
                                  when 'email_order_shipped'
                                    '<h1>SHIPMENT SUMMARY</h1> Dear {name}, your order {number} has been shipped. Shipped method: {shipping_name} <br>{order_table}<br>{tracking_url}'
                                  when 'email_order_cancelled'
                                    '<h1>ORDER {number} CANCELLED</h1> Dear {name}, your order has been cancelled. Please retain this cancellation information for your records. <br>{order_table}'
                                  when 'email_order_invoice'
                                    '<table style="width: 100%;"><tr><td><h1>INVOICE #{invoice_number}</h1> <h4>Order #{number}</h4><div>{current_date}</div></td><td style="text-align: center;"><img src="http://camaleon.tuzitio.com/media/132/logo2.png"></td></tr></table> <table style="width: 100%;"><tr><td><strong>Billing Information</strong><br>{billing_info}</td><td><strong>Shipping Address</strong><br>{shipping_info}</td></tr><tr><td colspan="2">{order_table}</td></tr></table>'
                                end
    end

    # return all keys accepted to replace in ecommerce emails
    def e_email_keys
      '{root_url} => site url, {date} => order date, {number} => order number, {name} => client first name, {full_name}, {order_table} => table of products of the order, {shipping_name} => shipping method name, {tracking_url} => the url of tracking, {shipping_info} => Shipping info, {billing_info} => Billing info, {invoice_number} => Sequential Invoice Number, {url} => Order Url'
    end

  end

  CamaleonCms::User.class_eval do
    has_many :carts, class_name: 'Plugins::Ecommerce::Cart', foreign_key: :user_id
    has_many :orders, class_name: 'Plugins::Ecommerce::Order', foreign_key: :user_id
  end

  CamaleonCms::Post.class_eval do
    has_many :product_variations, class_name: 'Plugins::Ecommerce::ProductVariation', foreign_key: :product_id, dependent: :destroy
    before_destroy :e_validate_related_orders

    private
    # verify if there are orders related to this product
    def e_validate_related_orders
      errors.add(:base, I18n.t('plugins.ecommerce.message.not_deletable_product')) if Plugins::Ecommerce::ProductItem.where(product_id: id).any?
    end
  end

  CamaleonCms::SiteDecorator.class_eval do
    # return the current system currency unit
    def current_unit
      h.e_system_currency
    end

    # return the current system currency
    def currency_code
      h.e_system_currency
    end

    def current_weight
      object.get_meta('_setting_ecommerce', {})[:current_weight].to_s.capitalize.presence || 'Kg'
    end

    # return all visible products fo current user in current site
    def the_products
      the_posts('commerce')
    end
  end
end
