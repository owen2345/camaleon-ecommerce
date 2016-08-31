class Plugins::Ecommerce::ProductService
  def initialize(site, product, variation_id = nil)
    @site = site
    @product = product
    @variation_id = variation_id
  end
  
  attr_reader :site, :product, :variation_id
  
  def available_qty
    if variation_id.present?
      product.decorate.get_variation(variation_id).qty || 0
    else
      product.get_field_value('ecommerce_qty').to_f || 0
    end
  end
end
