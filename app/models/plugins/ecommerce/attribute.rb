class Plugins::Ecommerce::Attribute < ActiveRecord::Base
  self.table_name='plugins_ecommerce_attributes'
  belongs_to :site
  has_many :values, class_name: 'Plugins::Ecommerce::Attribute', foreign_key: :parent_id, dependent: :destroy
  belongs_to :product_attribute, class_name: 'Plugins::Ecommerce::Attribute', foreign_key: :parent_id
  scope :only_group, ->{ where(parent_id: nil) }
  scope :only_value, ->{ where.not(parent_id: nil) }
  default_scope ->{ order(position: :ASC) }
end
