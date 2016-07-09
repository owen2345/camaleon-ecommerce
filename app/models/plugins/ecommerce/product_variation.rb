class Plugins::Ecommerce::ProductVariation < ActiveRecord::Base
  self.table_name='plugins_ecommerce_product_variations'
  belongs_to :product, class_name: "CamaleonCms::Post"

  # return all attribute values assigned to this product
  def attribute_values
    Plugins::Ecommerce::Attribute.only_value.where(id: self.attribute_ids.to_s.split(','))
  end
end
