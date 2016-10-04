class Plugins::Ecommerce::OrderService
  def initialize(site, order)
    @site = site
    @order = order
  end
  
  attr_reader :site, :order
  
  def product_owners
    owners = []
    order.products.each do |product|
      owners << product.owner if product.owner.present?
    end
    owners.uniq
  end
  
  def product_files
    files = []
    order.products.each do |product|
      files += product.get_fields('ecommerce_files').map do |f|
        CamaleonCmsLocalUploader::private_file_path(f, site)
      end
    end
    files.uniq
  end
end
