class Plugins::Ecommerce::Order < Plugins::Ecommerce::Cart
  self.table_name = 'plugins_ecommerce_orders'
  has_many :metas, ->{ where(object_class: 'Plugins::Ecommerce::Cart')}, :class_name => "CamaleonCms::Meta", foreign_key: :objectid, dependent: :delete_all
  default_scope { where(kind: 'order') }
  # status: bank_pending => pending of verification for bank transfer orders
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

  def accepted!
    update_columns({status: 'accepted', accepted_at: Time.current})
  end

  def shipped?
    status == 'shipped'
  end

  def shipped!(code)
    update_columns({status: 'shipped', shipped_at: Time.current})
    set_meta('consignment_number', code)
  end

  def canceled?
    status == 'canceled'
  end

  def canceled!
    update_columns({status: 'canceled', shipped_at: Time.current})
  end

  def received?
    status == 'received'
  end

  def bank_pending?
    status == 'bank_pending'
  end

  def bank_confirmed!
    update_columns({status: 'paid', updated_at: Time.current})
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
