class Plugins::Ecommerce::Front::CheckoutController < Plugins::Ecommerce::FrontController
  before_action :commerce_authenticate
  before_action :set_cart
  before_action :set_payment, only: [:pay_by_stripe, :pay_by_bank_transfer, :pay_by_credit_card, :pay_by_authorize_net, :pay_by_paypal]

  def index
    unless @cart.product_items.count > 0
      flash[:notice] = t('plugins.ecommerce.messages.cart_no_products', default: 'Not exist products in your cart')
      return redirect_to action: :cart_index
    end
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.checkout', default: 'Checkout')]
  end

  def step_address
    @cart.set_meta("billing_address", params[:order][:billing_address])
    @cart.set_meta("shipping_address", params[:order][:shipping_address])
    render nothing: true
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
        flash[:error] = errors.join('<br>')
        redirect_to :back
      else
        @cart.set_meta('free_order', true)
        mark_order_like_received(@cart)
        redirect_to plugins_ecommerce_orders_path
      end
    else
      flash[:error] = "Invalid complete payment"
      redirect_to :back
    end
  end

  def cart_index
    @products = @cart.product_items.decorate
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.shopping_cart', default: 'Shopping cart')]
  end

  def res_coupon
    code = params[:code].to_s.downcase
    res = @cart.discount_for(code)
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
      flash[:error] = t('plugins.ecommerce.messages.missing_variation', default: 'Invalid Product Variation')
      return redirect_to action: :cart_index
    end

    unless product.can_added?(qty, params[:variation_id])
      flash[:error] =  t('plugins.ecommerce.messages.not_enough_product_qty', product: product.the_variation_title(params[:variation_id]), qty: product.the_qty_real(params[:variation_id]), default: 'There is not enough products "%{product}" (Available %{qty})')
      return redirect_to :back
    end
    @cart.add_product(product, qty, params[:variation_id])
    flash[:notice] = t('plugins.ecommerce.messages.added_product_in_cart', default: 'Product added into cart')
    redirect_to action: :cart_index
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
        errors << t('plugins.ecommerce.messages.not_enough_product_qty', product: product.the_variation_title(item.variation_id), qty: product.the_qty_real(item.variation_id), default: 'There is not enough products "%{product}" (Available %{qty})')
      end
    end
    flash[:error] = errors.join('<br>') if errors.present?
    flash[:notice] = t('plugins.ecommerce.messages.cart_updated', default: 'Shopping cart updated') unless errors.present?
    redirect_to action: :cart_index
  end

  def cart_remove
    @cart.product_items.find(params[:product_item_id]).destroy
    flash[:notice] = t('plugins.ecommerce.messages.cart_deleted', default: 'Product removed from your shopping cart')
    redirect_to action: :cart_index
  end

  def cancel_order
    @cart.update({status: 'canceled', kind: 'order', closed_at: Time.now})
    flash[:notice] = t('plugins.ecommerce.messages.canceled_order', default: "Canceled Order")
    redirect_to plugins_ecommerce_orders_url
  end

  def pay_by_stripe
    result = Plugins::Ecommerce::CartService.new(current_site, @cart).
      pay_with_stripe(@payment,
        email: params[:stripeEmail],
        stripe_token: params[:stripeToken],
      )
    if result[:error].present?
      flash[:error] = result[:error]
      if result[:payment_error]
        flash[:payment_error] = true
      end
      redirect_to :back
    else
      mark_order_like_received(@cart)
      redirect_to plugins_ecommerce_orders_url
    end
  end

  def pay_by_bank_transfer
    @cart.set_meta("payment_data", params[:details])
    mark_order_like_received(@cart, 'bank_pending')
    redirect_to plugins_ecommerce_orders_url
  end

  def pay_by_authorize_net
    res = payment_pay_by_credit_card_authorize_net(@cart, @payment)
    if res[:error].present?
      flash[:error] = res[:error]
      flash[:payment_error] = true
      redirect_to :back
    else
      mark_order_like_received(@cart)
      redirect_to plugins_ecommerce_orders_url
    end
  end

  def success_paypal
    @cart.set_meta('payment_data', {token: params[:token], PayerID: params[:PayerID]})
    mark_order_like_received(@cart)
    redirect_to plugins_ecommerce_orders_url
  end

  def cancel_paypal
    # @cart = current_site.orders.find_by_slug(params[:order])
    redirect_to plugins_ecommerce_orders_url
  end

  def pay_by_paypal
    result = Plugins::Ecommerce::CartService.new(current_site, @cart).
      pay_with_paypal(@payment, ip: request.remote_ip)
    redirect_to result[:redirect_url]
  end

  private
  def set_cart
    @cart = Plugins::Ecommerce::UserCartService.new(current_site, current_user).get_cart
  end

  def set_bread
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.checkout', default: 'Checkout'), url_for(action: :cart_index)]
  end

  def set_payment
    @payment = current_site.payment_methods.actives.where(id: params[:payment][:payment_id]).first
    @cart.update_column(:payment_method_id, @payment.id)
  end
end
