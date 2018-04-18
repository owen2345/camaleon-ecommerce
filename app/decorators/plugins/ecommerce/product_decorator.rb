class Plugins::Ecommerce::ProductDecorator < CamaleonCms::PostDecorator

  def the_sku(variation_id = nil)
    sku(variation_id)
  end

  def sku(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).sku
    else
      is_variation_product? ? get_default_variation.sku : object.get_field_value('ecommerce_sku').to_s
    end
  end

  def the_price(variation_id = nil)
    h.e_parse_price(price(variation_id))
  end

  def the_weight(variation_id = nil)
    "#{h.current_site.current_weight} #{weight(variation_id)}"
  end

  def weight(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).weight || 0
    else
      is_variation_product? ? (get_default_variation.weight || 0) : object.get_field_value('ecommerce_weight').to_f || 0
    end
  end

  def the_qty(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).qty || 0
    else
      is_variation_product? ? map_variations_the_qty.map{|k,v| v }.reduce(&:+) : (object.get_field_value('ecommerce_qty').to_i || 0)
    end
  end

  # return the total (Integer) of products available to sell (doesn't include the qty of the current cart)
  def the_qty_real(variation_id = nil)
    return the_qty_real(get_default_variation.id) if !variation_id.present? && is_variation_product?
    carts = h.current_site.carts.active_cart.joins(:product_items)
    _q = variation_id.present? ? {variation_id: variation_id} : {product_id: object.id}
    _qty_in_carts = carts.where.not(id: h.e_current_cart.id).where("#{Plugins::Ecommerce::ProductItem.table_name}" => _q).sum("#{Plugins::Ecommerce::ProductItem.table_name}.qty")
    the_qty - _qty_in_carts
  end

  def the_photos
    is_variation_product? ? object.product_variations.pluck(:photo) : object.get_field_values('ecommerce_photos') || []
  end

  def in_stock?(variation_id = nil)
    return true if is_service?(variation_id)
    the_qty(variation_id) > 0
  end

  def price(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).amount || 0
    else
      is_variation_product? ? (get_default_variation.amount || 0) : object.get_field_value(:ecommerce_price).to_f || 0
    end
  end

  # return the title for variation prefixed with the title of the product
  def the_variation_title(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).title
      "#{ get_variation(variation_id).title } #{ "(#{ get_variation(variation_id).attribute_values.pluck(:label).join(', ').translate.presence })" if get_variation(variation_id).attribute_values.present? }"
    else
      "#{the_title}"
    end
    # "#{the_title}#{" - #{get_variation(variation_id).attribute_values.pluck(:label).join(', ').translate.presence || 'Not defined'}" if variation_id.present? }"
  end

  # return a product variation by id
  def get_variation(variation_id)
    object.cama_fetch_cache("_get_variation_#{variation_id}") do
      self.product_variations.find(variation_id)
    end
  end

  def the_tax(variation_id = nil)
    h.e_parse_price(tax(variation_id))
  end

  def tax(variation_id = nil)
    tax_rate_id = object.get_field_value(:ecommerce_tax)
    if tax_rate_id.present?
      percent = h.current_site.tax_rates.find(tax_rate_id).options[:rate].to_f  rescue 0
      price(variation_id) * percent / 100
    else # tax not defined
      0
    end
  end

  def the_stock_status(variation_id = nil)
    if in_stock?(variation_id)
      "<span class='label label-success'>#{I18n.t('plugins.ecommerce.product.in_stock')}</span>"
    else
      "<span class='label label-danger'>#{I18n.t('plugins.ecommerce.product.not_in_tock')}</span>"
    end
  end

  def eco_featured?
    object.get_field_value('ecommerce_featured').to_s.to_bool
  end

  def the_featured_status
    if eco_featured?
      "<span class='label label-primary'>#{I18n.t('plugins.ecommerce.product.featured')}</span>"
    else
      ""
    end
  end

  def product_type(variation_id = nil)
    return get_variation(variation_id).product_type if variation_id.present?
    return get_default_variation.product_type if is_variation_product?
    object.get_field_value('ecommerce_product_type').to_s
  end

  # check if the product is a service
  def is_service?(variation_id = nil)
    product_type(variation_id) == 'service_product'
  end

  # check if there are enough products to be purchased
  def can_added?(qty, variation_id = nil)
    return true if is_service?(variation_id)
    (the_qty(variation_id) - qty).to_i >= 0
  end

  def self.object_class_name
    'CamaleonCms::Post'
  end

  # verify if current product needs a variation id to be purchased
  # return true/false
  def valid_variation?(variation_id = nil)
    if self.product_variations.any?
      self.product_variations.where(id: variation_id).any?
    else
      true
    end
  end

  # check if current product is a variation product
  def is_variation_product?
    @_cache_is_variation_product ||= self.product_variations.any?
  end

  # return (Hash) all variations qty for each variation, sample: {1: 10, 5: 2, 3: 0}
  # note: this includes the quantity of items of user carts
  def map_variations_the_qty_real
    res = {}
    return res unless is_variation_product?
    object.product_variations.eager_load(:product).each do |var|
      res[var.id] = var.product.decorate.the_qty_real
    end
    res
  end

  # return (Hash) all variations qty for each variation, sample: {1: 10, 5: 2, 3: 0}
  def map_variations_the_qty
    res = {}
    return res unless is_variation_product?
    object.product_variations.each do |var|
      res[var.id] = var.qty
    end
    res
  end

  # return the first variation of a product
  def get_default_variation
    @_cama_cache_get_default_variation ||= object.product_variations.first
  end
end
