class Plugins::Ecommerce::Order < Plugins::Ecommerce::Cart
  self.table_name = 'plugins_ecommerce_orders'
  has_many :metas, ->{ where(object_class: 'Plugins::Ecommerce::Cart')}, :class_name => "CamaleonCms::Meta", foreign_key: :objectid, dependent: :delete_all
  default_scope { where(kind: 'order') }
  # status:
  #         bank_pending => pending of verification for bank transfer orders
  #         on_delivery => pending to mark as paid after after delivery
  #         paid => paid by some method
  #         canceled => canceled order
  #         shipped => shipped status
  #         accepted => received status

  def paid?
    status == 'paid'
  end

  def accepted?
    status == 'accepted'
  end

  def shipped?
    status == 'shipped'
  end

  def canceled?
    status == 'canceled'
  end

  def received?
    status == 'received'
  end

  def bank_pending?
    status == 'bank_pending'
  end

  def on_delivery_pending?
    status == 'on_delivery'
  end

  def payment_data
    get_meta('payment_data', {})
  end

  # return the date of the current status
  def action_date
    case object.status
      when 'paid'
        object.created_at
      when 'canceled'
        object.closed_at
      when 'shipped'
        object.shipped_at
      when 'accepted'
        object.accepted_at
    end
  end
end
