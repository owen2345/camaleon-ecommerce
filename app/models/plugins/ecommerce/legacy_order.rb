class Plugins::Ecommerce::LegacyOrder < CamaleonCms::TermTaxonomy
  default_scope { where(taxonomy: :ecommerce_order) }
  has_one :details, class_name: "Plugins::Ecommerce::OrderDetail", foreign_key: :order_id, dependent: :destroy
  has_many :products, foreign_key: :objectid, through: :term_relationships, :source => :objects
  belongs_to :customer, class_name: "CamaleonCms::User", foreign_key: :user_id

  def add_product(object)
    post_id = defined?(object.id) ? object.id : object.to_i
    term_relationships.where(objectid: post_id).first_or_create if post_id > 0
  end
  def remove_product(object)
    post_id = defined?(object.id) ? object.id : object.to_i
    term_relationships.where(objectid: post_id).destroy_all if post_id > 0
  end

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

  def canceled?
    status == 'canceled'
  end
  def unpaid?
    status == 'unpaid'
  end

  def paid?
    payment.present?
  end


  # set user in filter
  def self.set_user(user)
    user_id = defined?(user.id) ? user.id : user.to_i
    self.where(user_id: user_id)
  end


end
