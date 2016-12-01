## not used anymore (DEPRECATED)
class Plugins::Ecommerce::LegacyOrder < CamaleonCms::TermTaxonomy
  default_scope { where(taxonomy: :ecommerce_order) }
  has_one :details, class_name: "Plugins::Ecommerce::OrderDetail", foreign_key: :order_id, dependent: :destroy
  has_many :products, foreign_key: :objectid, through: :term_relationships, :source => :objects

  def payment_method
    Plugins::Ecommerce::PaymentMethod.find_by_id get_meta("payment")[:payment_id]
  end

  def payment
    payment = get_meta("payment")
    get_meta("pay_#{payment[:type]}".to_sym)
  end

  def shipping_method
    Plugins::Ecommerce::ShippingMethod.find_by_id get_meta("payment", {})[:shipping_method]
  end
end
