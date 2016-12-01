class Plugins::Ecommerce::OrderDecorator < Draper::Decorator
  delegate_all

  def the_status(include_date_action = false)
    res = if object.bank_pending? || object.on_delivery_pending?
            "<span class='label label-warning'>#{h.t("plugins.ecommerce.messages.order_status.#{object.status}", default: object.status.titleize)}</span>"
          elsif object.canceled?
            "<span class='label label-danger'>#{h.t("plugins.ecommerce.messages.order_status.#{object.status}", default: object.status.titleize)}</span>"
          else
            "<span class='label label-success'>#{h.t("plugins.ecommerce.messages.order_status.#{object.status}", default: object.status.titleize)}</span>"
          end
    res = "#{res} #{object.action_date}" if include_date_action
    res
  end

  def the_url_tracking
    if object.shipped?
      consignment_number = object.get_meta("consignment_number")
      _url = object.shipping_method.options[:url_tracking].gsub("{{consignment_number}}", consignment_number) rescue ''
    end
  end
end
