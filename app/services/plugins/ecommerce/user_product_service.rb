class Plugins::Ecommerce::UserProductService
  def initialize(site, user, product, variation_id = nil)
    @site = site
    @user = user
    @product = product
    @variation_id = variation_id
  end
  
  attr_reader :site, :user, :product, :variation_id
  
  def available_qty
    carts = site.carts.where.not(user_id: user.id).active_cart.joins(:product_items)
    if variation_id.present?
      (product.decorate.get_variation(variation_id).qty || 0) -
        carts.where("#{Plugins::Ecommerce::ProductItemDecorator.table_name}" =>
          {variation_id: variation_id}).sum("#{Plugins::Ecommerce::ProductItem.table_name}.qty")
    else
      (product.get_field_value('ecommerce_qty').to_f || 0) -
        carts.where("#{Plugins::Ecommerce::ProductItemDecorator.table_name}" =>
          {product_id: product.id}).sum("#{Plugins::Ecommerce::ProductItem.table_name}.qty")
    end
  end
end
