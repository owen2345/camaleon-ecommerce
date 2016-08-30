class Plugins::Ecommerce::ProductItemService
  def initialize(site, product_item)
    @site = site
    @product_item = product_item
  end
  
  attr_reader :site, :product_item
  
  def user
    @user ||= product_item.cart.user
  end
  
  def product
    @product ||= product_item.product
  end
  
  def decrement_qty!
    available_qty = UserProductService.new(
      site, user, product, product_item.variation_id).available_qty
    val = (available_qty - product_item.qty).to_i
    if val >= 0
      if product_item.variation_id.present?
        product_item.product_variation.update_column(:qty, val)
      else
        product.update_field_value('ecommerce_qty', val)
      end
    end
  end
end
