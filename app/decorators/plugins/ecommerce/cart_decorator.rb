class Plugins::Ecommerce::CartDecorator < Draper::Decorator
  delegate_all
  def the_sub_total
    h.e_parse_price(object.sub_total)
  end

  def the_total_discounts
    h.e_parse_price(object.total_discounts)
  end

  def the_total_amount
    h.e_parse_price(object.total_amount)
  end
  alias_method :the_price, :the_total_amount

  def the_tax_total
    h.e_parse_price(object.tax_total)
  end

  def the_weight_total
    "#{h.current_site.current_weight} #{sprintf('%.2f', object.weight_total)}"
  end

  def the_total_shipping
    h.e_parse_price(object.total_shipping)
  end

  # return the product titles in array format
  def products_title
    object.product_items.map{|i| p=i.product.decorate; p.the_variation_title(i.variation_id) }.join(', ')
  end

  # convert the cart into order with specific status
  def convert_to_order(status = 'paid')
    prepare_to_pay
    update_amounts
    object.update_columns(
      status: status,
      kind: 'order',
      received_at: Time.current
    )
    order = h.current_site.orders.find(object.id).decorate
    order.paid! if status == 'paid'
    order
  end
end
