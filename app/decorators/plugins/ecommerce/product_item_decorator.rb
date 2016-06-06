class Plugins::Ecommerce::ProductItemDecorator < Draper::Decorator
  delegate_all
  def the_sub_total
    "#{h.current_site.current_unit}#{sprintf('%.2f', object.sub_total)}"
  end

  def the_price
    product.decorate.the_price
  end

  def the_tax
    product.decorate.the_tax
  end

  def price
    product.decorate.price
  end
end
