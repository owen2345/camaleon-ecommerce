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
