## not used anymore (DEPRECATED)
class Plugins::Ecommerce::OrderDetail < ActiveRecord::Base
  self.table_name = "plugins_order_details"
  belongs_to :order, class_name: "Plugins::Ecommerce::Order", foreign_key: :order_id
end
