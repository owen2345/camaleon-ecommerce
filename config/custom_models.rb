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
    def products
      post_types.where(slug: 'commerce').first.try(:posts)
    end
  end
  
  CamaleonCms::User.class_eval do
    has_many :carts, class_name: 'Plugins::Ecommerce::Cart', foreign_key: :user_id
    has_many :orders, class_name: 'Plugins::Ecommerce::Order', foreign_key: :user_id
  end

  CamaleonCms::Post.class_eval do
    has_many :product_variations, class_name: 'Plugins::Ecommerce::ProductVariation', foreign_key: :product_id, dependent: :destroy
  end

  CamaleonCms::SiteDecorator.class_eval do
    def current_unit
      @current_unit ||= h.e_get_currency_units[object.meta[:_setting_ecommerce][:current_unit]]['symbol'] rescue '$'
    end
    def currency_code
      @currency_code ||= h.e_get_currency_units[object.meta[:_setting_ecommerce][:current_unit]]['code'] rescue 'USD'
    end
    def current_weight
      @current_weight ||= h.e_get_currency_weight[object.meta[:_setting_ecommerce][:current_weight]]['code'] rescue 'kg'
    end

    # return all visible products fo current user in current site
    def the_products
      the_posts('commerce')
    end
  end
end
