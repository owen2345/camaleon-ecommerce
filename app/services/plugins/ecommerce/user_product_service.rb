class Plugins::Ecommerce::UserProductService
  def initialize(site, user, product, variation_id = nil)
    @site = site
    @user = user
    @product = product
    @variation_id = variation_id
  end
  
  attr_reader :site, :user, :product, :variation_id
  
  def available_qty
    available_qty = Plugins::Ecommerce::ProductService.new(
      site, product, variation_id).available_qty
    available_qty -= qty_in_carts
  end
  
  private
  
  def qty_in_carts
    carts = site.carts.where.not(user_id: user.id).active_cart.joins(:product_items)
    if variation_id.present?
      carts.where("#{Plugins::Ecommerce::ProductItemDecorator.table_name}" =>
        {variation_id: variation_id}).sum("#{Plugins::Ecommerce::ProductItem.table_name}.qty")
    else
      carts.where("#{Plugins::Ecommerce::ProductItemDecorator.table_name}" =>
        {product_id: product.id}).sum("#{Plugins::Ecommerce::ProductItem.table_name}.qty")
    end
  end
end
