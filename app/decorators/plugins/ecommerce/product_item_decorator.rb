class Plugins::Ecommerce::ProductItemDecorator < Draper::Decorator
  delegate_all
  def the_title
    get_product.the_variation_title(object.variation_id)
  end

  def the_sub_total
    "#{h.current_site.current_unit}#{sprintf('%.2f', object.sub_total)}"
  end

  def the_price
    get_product.the_price(object.variation_id)
  end

  def the_tax
    get_product.the_tax(object.variation_id)
  end

  def price
    get_product.price(object.variation_id)
  end

  def get_product
    @_get_product ||= product.decorate
  end

  # return a product variation by id
  def get_variation
    @_get_variation ||= self.product_variation.decorate
  end
end
