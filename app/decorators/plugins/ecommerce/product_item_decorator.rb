class Plugins::Ecommerce::ProductItemDecorator < Draper::Decorator
  delegate_all
  def the_title
    get_product.the_variation_title(object.variation_id)
  end

  def the_url
    get_product.the_url(variation_id: object.variation_id)
  end

  def the_sub_total
    h.e_parse_price(object.sub_total)
  end

  def the_price
    get_product.the_price(object.variation_id)
  end

  def the_bucket
    get_product.the_bucket(object.variation_id)
  end

  def the_hours
    get_product.the_hours(object.variation_id)
  end

  def the_tax
    get_product.the_tax(object.variation_id)
  end

  def price
    get_product.price(object.variation_id)
  end

  def is_service
    get_product.is_service?(object.variation_id)
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
    val = get_product.the_qty(object.variation_id) - object.qty
    val = 0 if is_service
    if object.variation_id.present?
      product_variation.update_column(:qty, val)
    else
      product.update_field_value('ecommerce_qty', val)
    end
    val
  end

  # verify if the quantity of the cart item is avilable
  # return true if quantity is available
  def is_valid_qty?
    return true  if is_service
    (get_product.the_qty(object.variation_id) - object.qty).to_i >= 0
  end
end
