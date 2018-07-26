class Plugins::Ecommerce::Front::CheckoutController < Plugins::Ecommerce::FrontController
  before_action :commerce_authenticate, except: [:cart_add, :cart_update, :cart_remove, :cart_index]
  before_action :set_cart
  before_action :set_payment, only: [:pay_by_stripe, :pay_by_bank_transfer, :pay_by_credit_card, :pay_by_authorize_net, :pay_by_paypal, :pay_by_on_delivery]

  def index
    unless @cart.product_items.count > 0
      flash[:cama_ecommerce][:notice] = t('plugins.ecommerce.messages.cart_no_products', default: 'Not exist products in your cart')
      return redirect_to action: :cart_index
    end
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.checkout', default: 'Checkout')]
  end

  def step_address
    @cart.set_meta("billing_address", params[:order][:billing_address])
    @cart.set_meta("shipping_address", params[:order][:shipping_address])
    render inline: ''
  end

  def step_shipping
    @cart.update_column(:shipping_method_id, params[:shipping_method])
    if params[:next_step].present?
      render partial: plugin_view('partials/checkout/payments'), layout: false
    else
      render partial: plugin_view('partials/checkout/products_detail'), layout: false
    end
  end

  # free carts
  def complete_free_order
    if @cart.free_cart?
      errors = ecommerce_verify_cart_errors(@cart)
      if errors.present?
        flash[:cama_ecommerce][:error] = errors.join('<br>')
        redirect_to request.referer
      else
        hooks_run('plugin_ecommerce_before_complete_free_order', @cart)
        @cart.set_meta('free_order', true)
        commerce_mark_cart_received(@cart)
        hooks_run('plugin_ecommerce_after_complete_free_order', @cart)
        redirect_to plugins_ecommerce_orders_path
      end
    else
      flash[:cama_ecommerce][:error] = "Invalid complete payment"
      redirect_to request.referer
    end
  end

  def cart_index
    @products = @cart.product_items.decorate
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.shopping_cart', default: 'Shopping cart')]
  end

  def res_coupon
    code = params[:code].to_s.downcase
    res = {error: '', discount: 0, coupon: nil}

    code.blank? ? res[:error] = 'coupon_not_found' : res = @cart.discount_for(code)
        
    if res[:error].present?
      render inline: commerce_coupon_error_message(res[:error], res[:coupon]), status: 500
    else
      @cart.update_column(:coupon, code)
      render partial: plugin_view('partials/checkout/products_detail'), layout: false
    end
  end

  # params[cart]: product_id,  qty
  def cart_add
    data = params[:cart]
    qty = data[:qty].to_f rescue 0
    product = current_site.products.find(data[:product_id]).decorate
    unless product.valid_variation?(params[:variation_id])
      flash[:cama_ecommerce][:error] = t('plugins.ecommerce.messages.missing_variation', default: 'Invalid Product Variation')
      return params[:format] == 'json' ? render(json: flash.discard(:cama_ecommerce).to_hash) : (redirect_to action: :cart_index)
    end

    unless product.can_added?(qty, params[:variation_id])
      flash[:cama_ecommerce][:error] =  t('plugins.ecommerce.messages.not_enough_product_qty', product: product.the_variation_title(params[:variation_id]), qty: product.the_qty(params[:variation_id]), default: 'There is not enough products "%{product}" (Available %{qty})')
      return params[:format] == 'json' ? render(json: flash.discard(:cama_ecommerce).to_hash) : (redirect_to request.referer)
    end
    @cart.add_product(product, qty, params[:variation_id])
    flash[:cama_ecommerce][:notice] = t('plugins.ecommerce.messages.added_product_in_cart', default: 'Product added into cart')
    params[:format] == 'json' ? render(json: flash.discard(:cama_ecommerce).to_hash) : (redirect_to action: :cart_index)
  end

  def cart_update
    errors = []
    params[:product_items].each do |data|
      item =  @cart.product_items.find(data[:item_id])
      product = item.product.decorate
      qty = data[:qty].to_f
      if product.can_added?(qty, item.variation_id)
        @cart.add_product(product, qty, item.variation_id)
      else
        errors << t('plugins.ecommerce.messages.not_enough_product_qty', product: product.the_variation_title(item.variation_id), qty: product.the_qty(item.variation_id), default: 'There is not enough products "%{product}" (Available %{qty})')
      end
    end
    flash[:cama_ecommerce][:error] = errors.join('<br>') if errors.present?
    flash[:cama_ecommerce][:notice] = t('plugins.ecommerce.messages.cart_updated', default: 'Shopping cart updated') unless errors.present?
    params[:format] == 'json' ? render(json: flash.discard(:cama_ecommerce).to_hash) : (redirect_to action: :cart_index)
  end

  def cart_remove
    @cart.product_items.find(params[:product_item_id]).destroy
    flash[:cama_ecommerce][:notice] = t('plugins.ecommerce.messages.cart_deleted', default: 'Product removed from your shopping cart')
    params[:format] == 'json' ? render(json: flash.discard(:cama_ecommerce).to_hash) : (redirect_to action: :cart_index)
  end

  def cancel_order
    @cart.update({status: 'canceled', kind: 'order', closed_at: Time.now})
    flash[:cama_ecommerce][:notice] = t('plugins.ecommerce.messages.canceled_order', default: "Canceled Order")
    params[:format] == 'json' ? render(json: flash.discard(:cama_ecommerce).to_hash) : (redirect_to plugins_ecommerce_orders_url)
  end

  def pay_by_stripe
    result = Plugins::Ecommerce::CartService.new(current_site, @cart).
      pay_with_stripe(payment_method: @payment,
        email: params[:stripeEmail],
        stripe_token: params[:stripeToken],
      )
    if result[:error].present?
      flash[:cama_ecommerce][:error] = result[:error]
      if result[:payment_error]
        flash[:payment_error] = true
      end
      redirect_to request.referer
    else
      commerce_mark_cart_received(@cart)
      redirect_to plugins_ecommerce_orders_url
    end
  end

  def pay_by_bank_transfer
    @cart.set_meta("payment_data", params[:details])
    commerce_mark_cart_received(@cart, 'bank_pending')
    redirect_to plugins_ecommerce_orders_url
  end

  def pay_by_on_delivery
    @cart.set_meta("payment_data", params[:details])
    commerce_mark_cart_received(@cart, 'on_delivery')
    redirect_to plugins_ecommerce_orders_url
  end

  def pay_by_authorize_net
    res = Plugins::Ecommerce::CartService.new(current_site, @cart).
      pay_with_authorize_net(payment_method: @payment, ip: request.remote_ip,
        first_name: params[:firstName],
        last_name: params[:lastName],
        number: params[:cardNumber],
        exp_month: params[:expMonth],
        exp_year: params[:expYear],
        cvc: params[:cvCode],
      )
    if res[:error].present?
      flash[:cama_ecommerce][:error] = res[:error]
      flash[:payment_error] = true
      redirect_to request.referer
    else
      commerce_mark_cart_received(@cart)
      redirect_to plugins_ecommerce_orders_url
    end
  end

  def success_paypal
    response = @cart.paypal_gateway.purchase(Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(@cart.total_amount), {
      :ip => request.remote_ip,
      :token => params[:token],
      :payer_id => params[:PayerID]
    })

    if response.success?
      @cart.set_meta('payment_data', {token: params[:token], PayerID: params[:PayerID], ip: request.remote_ip})
      commerce_mark_cart_received(@cart)
    else
      flash[:cama_ecommerce][:error] = response.message
    end
    redirect_to plugins_ecommerce_orders_url
  end

  def cancel_paypal
    redirect_to plugins_ecommerce_orders_url
  end

  def pay_by_paypal
    result = Plugins::Ecommerce::CartService.new(current_site, @cart).
      pay_with_paypal(ip: request.remote_ip, return_url: plugins_ecommerce_checkout_success_paypal_url(order: @cart.slug), cancel_return_url: plugins_ecommerce_checkout_cancel_paypal_url(order: @cart.slug))
    redirect_to result[:redirect_url]
  end

  private
  def set_cart
    @cart = e_current_cart
  end

  def set_bread
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.checkout', default: 'Checkout'), url_for(action: :cart_index)]
  end

  def set_payment
    @payment = current_site.payment_methods.actives.where(id: params[:payment][:payment_id]).first
    @cart.update_column(:payment_method_id, @payment.id)
  end
end
