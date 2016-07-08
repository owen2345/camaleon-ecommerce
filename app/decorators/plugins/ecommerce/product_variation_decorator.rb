class Plugins::Ecommerce::ProductVariationDecorator < Draper::Decorator
  delegate_all
  def the_price
    "#{h.current_site.current_unit}#{sprintf('%.2f', object.amount)}"
  end

  def the_title
    get_product.the_variation_title(object.id)
  end

  def the_weight
    "#{h.current_site.current_weight} #{object.weight}"
  end

  def get_product
    @_cache_get_product ||= object.product.decorate
  end
end
