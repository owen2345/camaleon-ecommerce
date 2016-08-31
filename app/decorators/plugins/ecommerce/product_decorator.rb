class Plugins::Ecommerce::ProductDecorator < CamaleonCms::PostDecorator

  def the_sku(variation_id = nil)
    sku(variation_id)
  end

  def sku(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).sku
    else
      object.get_field_value('ecommerce_sku').to_s
    end
  end

  def the_price(variation_id = nil)
    "#{h.current_site.current_unit}#{sprintf('%.2f', price(variation_id))}"
  end

  def the_weight(variation_id = nil)
    "#{h.current_site.current_weight} #{weight(variation_id)}"
  end

  def weight(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).weight || 0
    else
      object.get_field_value('ecommerce_weight').to_f || 0
    end
  end

  def the_qty(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).qty || 0
    else
      object.get_field_value('ecommerce_qty') || 0
    end
  end

  def the_photos
    object.get_field_values('ecommerce_photos') || []
  end

  def in_stock?(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).qty > 0
    else
      object.get_field_value('ecommerce_stock').to_s.to_bool
    end
  end

  def price(variation_id = nil)
    if variation_id.present?
      get_variation(variation_id).amount || 0
    else
      object.get_field_value(:ecommerce_price).to_f || 0
    end
  end

  # return the title for variation prefixed with the title of the product
  def the_variation_title(variation_id = nil)
    "#{the_title}#{" - #{get_variation(variation_id).attribute_values.pluck(:label).join(', ').translate.presence || 'Not defined'}" if variation_id.present? }"
  end

  # return a product variation by id
  def get_variation(variation_id)
    object.cama_fetch_cache("_get_variation_#{variation_id}") do
      self.product_variations.find(variation_id)
    end
  end

  def the_tax(variation_id = nil)
    tax(variation_id)
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
    if in_stock?(variation_id) && the_qty_real.to_i > 0
      "<span class='label label-success'>#{I18n.t('plugin.ecommerce.product.in_stock')}</span>"
    else
      "<span class='label label-danger'>#{I18n.t('plugin.ecommerce.product.not_in_tock')}</span>"
    end
  end

  def eco_featured?
    object.get_field_value('ecommerce_featured').to_s.to_bool
  end

  def the_featured_status
    if eco_featured?
      "<span class='label label-primary'>#{I18n.t('plugin.ecommerce.product.featured')}</span>"
    else
      ""
    end
  end

  # return the total of products available to sell
  def the_qty_real(variation_id = nil)
    if h.current_user
      Plugins::Ecommerce::UserProductService.new(
        h.current_site, h.current_user, object, variation_id).available_qty
    else
      Plugins::Ecommerce::ProductService.new(
        h.current_site, object, variation_id).available_qty
    end
  end

  # check if there are enough products to be purchased
  def can_added?(qty, variation_id = nil)
    (the_qty_real(variation_id) - qty).to_i >= 0
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
end
