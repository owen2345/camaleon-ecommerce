class Ecommerce::ProductDecorator < CamaleonCms::PostDecorator
  def the_sku
    object.get_field_value('ecommerce_sku').to_s
  end
  def the_price
    "#{h.current_site.current_unit}#{sprintf('%.2f', price)}"
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

  def price
    object.get_field_value(:ecommerce_price).to_f || 0
  end

  def the_tax
    tax
  end

  def tax
    tax_rate_id = object.get_field_value(:ecommerce_tax)
    if tax_rate_id.present?
      percent = h.current_site.tax_rates.find(tax_rate_id).options[:rate].to_f  rescue 0
      price * percent / 100
    end
  end

  def the_stock_status
    if in_stock? && the_qty_real.to_i > 0
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
  def the_qty_real
    object.get_field_value('ecommerce_qty').to_f || 0
  end

  # decrement products quantity
  # return false if the quantity is not enough to be decremented
  def decrement_qty(qty)
    val = (the_qty_real - qty).to_i
    if val >= 0
      object.update_field_value('ecommerce_qty', val)
      true
    else
      false
    end
  end

  # check if there are enough products to be purchased
  def can_added?(qty)
    val = (the_qty_real - qty).to_i
    val >= 0
  end

  def self.object_class_name
    'CamaleonCms::Post'
  end
end
