class Ecommerce::ProductDecorator < CamaleonCms::PostDecorator
  def the_sku
    object.get_field_value('ecommerce_sku').to_s
  end
  def the_price
    "#{h.current_site.current_unit}#{sprintf('%.2f', object.get_field_value('ecommerce_price'))}"
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

  def the_qty_real
    object.get_field_value('ecommerce_qty').to_f || 0
  end

  def self.object_class_name
    'CamaleonCms::Post'
  end
end
