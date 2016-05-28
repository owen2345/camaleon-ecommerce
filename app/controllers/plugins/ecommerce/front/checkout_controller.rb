=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::Front::CheckoutController < Plugins::Ecommerce::FrontController

  before_action :set_cart

  def index
    @products = @cart.product_items
    unless @products.size > 0
      flash[:notice] = t('plugins.ecommerce.messages.cart_no_products', default: 'Not exist products in your cart')
      return redirect_to action: :cart_index
    end
    @ecommerce_bredcrumb << [t('plugins.ecommerce.messages.checkout', default: 'Checkout')]
  end

  def processing
    @cart.update_column(:shipping_method_id, params[:order][:payment][:shipping_method])
    payment_amount = @cart.total_to_pay
    @cart.set_meta("billing_address", params[:order][:billing_address])
    @cart.set_meta("shipping_address", params[:order][:shipping_address])
    order = @cart.make_order
    if payment_amount > 0
      redirect_to plugins_ecommerce_order_select_payment_path(order: order.slug)
    else # free cart
      errors = ecommerce_verify_cart_errors(order)
      if errors.present?
        flash[:error] = errors.join('<br>')
        redirect_to :back
      else
        mark_order_like_received(order)
        flash[:notice] = t('plugins.ecommerce.messages.saved_order', default: 'Saved Order')
        redirect_to plugins_ecommerce_orders_path
      end
    end
  end

  def cart_index
    @products = @cart.product_items
    @ecommerce_bredcrumb << [t('plugins.ecommerce.messages.shopping_cart', default: 'Shopping cart')]
  end

  def res_coupon
    res = @cart.discount_for(params[:code].to_s.parameterize)
    if res[:error].present?
      render inline: commerce_coupon_error_message(res[:error], res[:coupon]), status: 500
    else
      render json: {code: params[:code], discount_type: res[:coupon].get_option('discount_type'), discount: res[:discount], text: "#{res[:coupon].decorate.the_amount}"}
    end
  end

  # params[cart]: product_id,  qty
  def cart_add
    data = params[:cart]
    qty = data[:qty].to_f rescue 0
    product = current_site.products.find(data[:product_id]).decorate
    unless product.can_added?(qty)
      flash[:error] =  t('plugins.ecommerce.messages.not_enough_product_qty', product: product.the_title, qty: product.the_qty_real, default: 'There is not enough products "%{product}" (%{qty})')
      return redirect_to :back
    end
    @cart.add_product(product)
    flash[:notice] = t('plugins.ecommerce.messages.added_product_in_cart', default: 'Product added into cart')
    redirect_to action: :index
  end

  def cart_update
    errors = []
    params[:products].each do |data|
      product = @cart.products.find(data[:product_id]).decorate
      qty = data[:qty].to_f
      if product.can_added?(qty)
        @cart.add_product(product, qty)
      else
        errors << t('plugins.ecommerce.messages.not_enough_product_qty', product: product.the_title, qty: product.the_qty_real, default: 'There is not enough products "%{product}" (%{qty})')
      end
    end
    flash[:error] = errors.join('<br>') if errors.present?
    flash[:notice] = t('plugins.ecommerce.messages.cart_updated', default: 'Shopping cart updated') unless errors.present?
    redirect_to action: :cart_index
  end

  def cart_remove
    @cart.remove_product(params[:product_id])
    flash[:notice] = t('plugins.ecommerce.messages.cart_deleted', default: 'Product removed from your shopping cart')
    redirect_to action: :cart_index
  end

  def orders
    render json: current_site.orders.set_user(current_user)
  end

  private
  def set_cart
    if signin?
      @cart = current_site.carts.set_user(current_user).first_or_create(name: "Cart by #{current_user.id}")
    else
      cookies[:return_to] = request.referer
      redirect_to plugins_ecommerce_login_path
    end
  end
end
