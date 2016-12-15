class RemoveEcommerceStockField < ActiveRecord::Migration
  def change
    Cama::PostType.where(slug: 'commerce').each do |pt|
      pt.get_field_object('ecommerce_stock').try(:destroy)
    end
  end
end
