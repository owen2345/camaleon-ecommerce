module Plugins::Ecommerce::EcommerceEmailHelper
  include CamaleonCms::EmailHelper

  # mark current cart into order with specific status
  def commerce_mark_cart_received(cart, status = 'paid')
    args = {cart: cart, status: status}; hooks_run('commerce_before_payment_completed', args)
    order = cart.convert_to_order(status)
    order.set_meta('locale', I18n.locale)
    commerce_order_send_mail(order)
    flash[:cama_ecommerce][:notice] = t('plugins.ecommerce.messages.payment_completed', default: "Payment completed successfully")
    args = {order: order, status: status}; hooks_run("commerce_after_payment_completed", args)
    order
  end

  # return translated message
  def commerce_coupon_error_message(error_code, coupon = nil)
    case error_code
      when 'coupon_not_found'
        t('plugins.ecommerce.messages.coupon_not_found', default: "Coupon not found")
      when 'coupon_expired'
        t('plugins.ecommerce.messages.coupon_expired', default: 'Coupon Expired')
      when 'inactive_coupon'
        t('plugins.ecommerce.messages.inactive_coupon', default: 'Coupon disabled')
      when 'times_exceeded'
        t('plugins.ecommerce.messages.times_exceeded', default: 'Number of times exceeded')
      when 'required_minimum_price'
        t('plugins.ecommerce.messages.required_minimum_price', min_amount: coupon.min_cart_total, default: 'Your amount should be great than %{min_amount}')
      else
        'Unknown error'
    end
  end

  # verify all products and qty, coupons availability
  # return an array of errors
  def ecommerce_verify_cart_errors(cart)
    errors = []
    # products verification
    cart.product_items.decorate.each do |item|
      unless item.is_valid_qty?
        product = item.product.decorate
        errors << t('plugins.ecommerce.messages.not_enough_product_qty', product: product.the_variation_title(item.variation_id), qty: product.the_qty(item.variation_id), default: 'There is not enough products "%{product}" (Available %{qty})')
      end
    end

    # coupon verification
    res = cart.discount_for(cart.coupon)
    if res[:error].present?
      errors << commerce_coupon_error_message(res[:error], res[:coupon])
      cart.update_column(:coupon, '')
    end

    args = {cart: cart, errors: errors}; hooks_run("commerce_on_error_verifications", args)
    errors
  end

  # send the email to the user for specific events or status
  # event: (String) email_order_received | email_order_shipped | email_order_cancelled | email_order_confirmed_bank | email_order_confirmed_on_delivery
  def commerce_order_send_mail(order, event = 'email_order_received')
    bk_l = I18n.locale
    I18n.locale = order.get_meta('locale', 'en').to_s
    subject, content_key = case event
                         when 'email_order_received'
                           [I18n.t('plugins.ecommerce.email.order_received_label', default: 'Order Received'), 'email_order_received']
                         when 'email_order_confirmed'
                           [I18n.t('plugins.ecommerce.email.order_confirmed_label', default: 'Order Confirmed'), 'email_order_confirmed']
                         when 'email_order_confirmed_bank'
                           [I18n.t('plugins.ecommerce.email.order_bank_confirmed_label', default: 'Order Bank Confirmed'), 'email_order_confirmed']
                         when 'email_order_confirmed_on_delivery'
                           [I18n.t('plugins.ecommerce.email.order_on_delivery_confirmed_label', default: 'Order on Delivery Confirmed'), 'email_order_confirmed']
                         when 'email_order_shipped'
                           [I18n.t('plugins.ecommerce.email.order_shipped_label', default: 'Order Shipped'), 'email_order_shipped']
                         when 'email_order_cancelled'
                           [I18n.t('plugins.ecommerce.email.order_cancelled_label', default: 'Order Cancelled'), 'email_order_cancelled']
                       end
    data = {template_name: nil, content: current_site.e_email_for(content_key).to_s.translate, files: []}
    replaces = {
      order_table: render_to_string(partial: 'plugins/ecommerce/partials/email/product_table', locals: {order: order}),
      shipping_info: render_to_string(partial: 'plugins/ecommerce/partials/email/shipping_address', locals: {order: order}),
      billing_info: render_to_string(partial: 'plugins/ecommerce/partials/email/billing_address', locals: {order: order}),
      cancelled_description: order.get_meta('description').to_s,
      root_url: current_site.the_url,
      date: order.the_created_at,
      current_date: l(Date.today, format: :long),
      number: order.slug,
      name: order.user.first_name,
      full_name: order.user.fullname,
      tracking_url: order.the_url_tracking.to_s,
      shipping_name: order.the_shipping_method.to_s,
      invoice_number: order.invoice_number.to_s,
      status: order.the_status,
      url: order.the_url
    }
    args={order: order, replaces: replaces}; hooks_run('commerce_custom_email_replacements', args) # permit to add custom replacements

    if order.status == 'paid'
      order.products.each do |product|
        data[:files] += product.get_fields('ecommerce_files').map{|f| CamaleonCmsLocalUploader::private_file_path(f, current_site) }
      end
      data[:files] = data[:files].uniq
      pdf_path = order.the_invoice_path
      File.open(pdf_path, 'wb'){|file| file << WickedPdf.new.pdf_from_string(current_site.e_email_for('email_order_invoice').to_s.translate.to_s.cama_replace_codes(replaces, format_code = '{'), encoding: 'utf8') }
      data[:files] << pdf_path
      order.update_column(:invoice_path, pdf_path.split('/').last)
    end
    data[:content] = data[:content].to_s.cama_replace_codes(replaces, format_code = '{')
    cama_send_email(order.user.email, subject, data)
    I18n.locale = bk_l
  end
end
