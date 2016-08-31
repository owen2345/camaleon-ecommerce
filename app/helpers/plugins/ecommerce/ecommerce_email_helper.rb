module Plugins::Ecommerce::EcommerceEmailHelper
  include CamaleonCms::EmailHelper

  def mark_order_like_received(cart, status = 'paid')
    cart.prepare_to_pay
    cart.update_amounts
    cart.mark_paid(status)
    order = cart.convert_to_order

    # send email to buyer
    commerce_send_order_received_email(order)

    # Send email to products owner
    commerce_send_order_received_admin_notice(order)

    flash[:notice] = t('plugins.ecommerce.messages.payment_completed', default: "Payment completed successfully")
    args = {order: order}; hooks_run("commerce_after_payment_completed", args)
    
    order
  end

  def commerce_send_order_received_email(order, is_after_bank_confirmation = false)
    data = _commerce_prepare_send_order_email_data(order)
    if is_after_bank_confirmation
      cama_send_email(order.user.email, t('plugin.ecommerce.mail.order_confirmed.subject'), {template_name: 'order_confirmed', extra_data: data[:extra_data], attachs: data[:files]})
    else
      data.delete(:files) unless order.paid?
      cama_send_email(order.user.email, t('plugin.ecommerce.email.order_received.subject'), {template_name: 'order_received', extra_data: data[:extra_data], attachs: data[:files]})
    end
  end

  def commerce_send_order_received_admin_notice(order)
    data = _commerce_prepare_send_order_email_data(order)
    data[:owners].each do |user|
      data[:extra_data][:admin] = user
      cama_send_email(user.email, t('plugin.ecommerce.email.order_received_admin.subject'), {template_name: 'order_received_admin', extra_data: data[:extra_data], attachs: data[:files]})
    end
  end

  def send_recovery_cart_email(order)
    extra_data = {
      :fullname => order.user.fullname,
      :order => order
    }
    send_email(order.user.email, t('plugin.ecommerce.email.recovery_cart.subject'), '', nil, [], 'recovery_cart', nil, extra_data)
    Rails.logger.info "Send recovery to #{order.user.email} with order #{order.slug}"
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
        errors << t('plugins.ecommerce.messages.not_enough_product_qty', product: product.the_title, qty: product.the_qty_real, default: 'There is not enough products "%{product}" (Available %{qty})')
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

  private
  def _commerce_prepare_send_order_email_data(order)
    data = {}
    data[:extra_data] = {
      :fullname => order.user.fullname,
      :order_slug => order.slug,
      :order_url => plugins_ecommerce_order_show_url(order: order.slug),
      :billing_information => order.get_meta('billing_address'),
      :shipping_address => order.get_meta('shipping_address'),
      :subtotal => order.cache_the_sub_total,
      :total_cost => order.cache_the_total,
      :order => order
    }
    files = []
    owners = []
    order.products.each do |product|
      files += product.get_fields('ecommerce_files').map{|f| CamaleonCmsLocalUploader::private_file_path(f, current_site) }
      owners << product.owner if product.owner.present?
    end
    data[:owners] = owners.uniq
    data[:files] = files.uniq
    data
  end

end
