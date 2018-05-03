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

  # check if item is a phisical product, to not display shipping address form
  def contains_physical_products?
    object.product_items.find { |product_item|
      !product_item.product.decorate.is_service?
    }.present?
  end

  # return created at date formatted
  def the_created_at(format = :long)
    h.l(object.created_at, format: format.to_sym)
  end

  def the_paid_at(format = :long)
    h.l(object.paid_at, format: format.to_sym) rescue ''
  end

  def the_received_at(format = :long)
    h.l(object.received_at, format: format.to_sym) rescue ''
  end

  def the_shipped_at(format = :long)
    h.l(object.shipped_at, format: format.to_sym) rescue ''
  end

  # return shipping method title
  def the_shipping_method
    object.shipping_method.try(:decorate).try(:the_title)
  end

  # return the url of the current order
  def the_url
    h.plugins_ecommerce_order_show_path(order: object.slug)
  end

  # mark current order as paid and set a invoice number
  def paid!
    update_columns(invoice_number: get_invoice_number, status: 'paid', paid_at: Time.current)
  end

  def accepted!
    update_columns({status: 'accepted', accepted_at: Time.current})
  end

  def shipped!(code)
    update_columns({status: 'shipped', shipped_at: Time.current})
    set_meta('consignment_number', code)
  end

  def canceled!
    update_columns({status: 'canceled', closed_at: Time.current})
  end

  def bank_confirmed!
    paid!
  end

  def on_delivery_confirmed!
    paid!
  end

  # return the invoice pdf path
  def the_invoice_path
    folder = CamaleonCmsLocalUploader::private_file_path('invoices', h.current_site).to_s
    FileUtils.mkdir_p(folder) unless Dir.exist?(folder)
    File.join(folder, "#{object.invoice_number.presence || object.slug}.pdf").to_s
  end

  private
  # return a new invoice number
  def get_invoice_number
    res = h.current_site.e_invoice_number_from
    new_inv = res + 1
    h.current_site.e_set_setting('invoice_number_from', new_inv)
    h.cama_send_mail_to_admin(I18n.t('plugins.ecommerce.email.invoice_number_exceeded_subject', default: 'Invoice Number Exceeded.'), {content: I18n.t('plugins.ecommerce.email.invoice_number_exceeded_body', default: 'The Invoice Number %{number} was exceeded. Please review ecommerce settings.', number: new_inv)}) if new_inv >= h.current_site.e_invoice_number_to
    res
  end
end
