Site.class_eval do
  #attr_accessible :my_id
  has_many :carts, :class_name => "Plugins::Ecommerce::Models::Cart", foreign_key: :parent_id, dependent: :destroy
  has_many :orders, :class_name => "Plugins::Ecommerce::Models::Order", foreign_key: :parent_id, dependent: :destroy
  has_many :payment_methods, :class_name => "Plugins::Ecommerce::Models::PaymentMethod", foreign_key: :parent_id, dependent: :destroy
  has_many :shipping_methods, :class_name => "Plugins::Ecommerce::Models::ShippingMethod", foreign_key: :parent_id, dependent: :destroy
  has_many :coupons, :class_name => "Plugins::Ecommerce::Models::Coupon", foreign_key: :parent_id, dependent: :destroy
  has_many :tax_rates, :class_name => "Plugins::Ecommerce::Models::TaxRate", foreign_key: :parent_id, dependent: :destroy
end

SiteDecorator.class_eval do
  def current_unit
    @current_unit ||= h.e_get_currency_units[object.meta[:_setting_ecommerce][:current_unit]]['symbol'] rescue '$'
  end
  def currency_code
    @currency_code ||= h.e_get_currency_units[object.meta[:_setting_ecommerce][:current_unit]]['code'] rescue 'USD'
  end
  def current_weight
    @current_weight ||= h.e_get_currency_weight[object.meta[:_setting_ecommerce][:current_weight]]['code'] rescue 'kg'
  end
end

PostDecorator.class_eval do
  def the_sku
    object.get_field_value('ecommerce_sku').to_s
  end
  def the_price
    "#{h.current_site.current_unit} #{object.get_field_value('ecommerce_price').to_f}"
  end
  def the_weight
    "#{h.current_site.current_weight} #{object.get_field_value('ecommerce_weight').to_f}"
  end
  def the_qty
    object.get_field_value('ecommerce_qty') || 0
  end
  def the_photos
    object.get_field_values('ecommerce_photos') || []
  end
  def in_stock?
    object.get_field_value('ecommerce_stock').to_s.to_bool
  end
  def the_stock_status
    if in_stock? && the_qty_real.to_i > 0
      "<span class='label label-success'>#{I18n.t('plugin.ecommerce.product.in_stock')}</span>"
    else
      "<span class='label label-danger'>#{I18n.t('plugin.ecommerce.product.not_in_tock')}</span>"
    end
  end

  def featured?
    object.get_field_value('ecommerce_featured').to_s.to_bool
  end
  def the_featured_status
    if featured?
      "<span class='label label-primary'>#{I18n.t('plugin.ecommerce.product.featured')}</span>"
    else
      ""
    end
  end

  def the_qty_real
    object.get_field_value('ecommerce_qty') || 0
  end
end