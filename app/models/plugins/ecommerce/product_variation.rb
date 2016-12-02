class Plugins::Ecommerce::ProductVariation < ActiveRecord::Base
  self.table_name='plugins_ecommerce_product_variations'
  belongs_to :product, class_name: "CamaleonCms::Post"
  before_destroy :verify_related_orders

  # return all attribute values assigned to this product
  def attribute_values
    Plugins::Ecommerce::Attribute.only_value.where(id: self.attribute_ids.to_s.split(','))
  end

  private
  def verify_related_orders
    errors.add(:base, t('plugin.ecommerce.message.not_deletable_product_variations')) if Plugins::Ecommerce::ProductItem.where(variation_id: id).any?
  end
end
