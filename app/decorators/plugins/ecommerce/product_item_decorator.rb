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
    @_get_product ||= object.product.decorate
  end

  # return a product variation by id
  def get_variation
    @_get_variation ||= self.product_variation.decorate
  end

  # update quantity of product or product variation used in current cart item
  def decrement_qty!
    val = (get_product.the_qty_real(object.variation_id) - object.qty).to_i
    if val >= 0
      if object.variation_id.present?
        object.product_variation.update_column(:qty, val)
      else
        get_product.update_field_value('ecommerce_qty', val)
      end
    end
  end

  # verify if the quantity of the cart item is avilable
  # return true if quantity is available
  def is_valid_qty?
    (get_product.the_qty_real(object.variation_id) - object.qty).to_i >= 0
  end
end
