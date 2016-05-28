=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::Front::OrdersController < Plugins::Ecommerce::FrontController
  before_action :set_payment, only: [:pay_by_stripe, :pay_by_bank_transfer, :pay_by_credit_card, :pay_by_authorize_net, :pay_by_paypal]
  before_action :set_bread
  def index
    @orders = current_site.orders.set_user(current_user).all
    render "index"
  end

  def select_payment
    @order = current_site.orders.find_by_slug(params[:order])
    errors = ecommerce_verify_cart_errors(@order)
    flash.now[:error] = errors.join('<br>') if errors.present?
    if params[:cancel].present?
      @order.update({status: 'canceled'})
      @order.details.update({closed_at: Time.now})
      flash[:notice] = t('plugins.ecommerce.messages.canceled_order', default: 'Order canceled')
      redirect_to action: :index
    end
    @ecommerce_bredcrumb << [t('plugins.ecommerce.messages.processing_order', default: 'Payment order #%{order}', order: params[:order])]
  end

  def show
    @order = current_site.orders.find_by_slug(params[:order]).decorate
    @ecommerce_bredcrumb << [t('plugins.ecommerce.messages.detail_order', default: "Detail order: #%{order}", order: params[:order])]
  end

  def cancel_order
    @order = current_site.orders.find_by_slug(params[:order])
    @order.update({status: 'canceled'})
    @order.details.update({closed_at: Time.now})
    flash[:notice] = t('plugins.ecommerce.messages.canceled_order', default: "Canceled Order")
    redirect_to action: :index
  end

  # pay by stripe
  def pay_by_stripe
    require 'stripe'
    Stripe.api_key = @payment.options[:stripe_id]
    customer = Stripe::Customer.create(:email => params[:stripeEmail], :source  => params[:stripeToken])
    begin
      charge = Stripe::Charge.create(
        :customer    => customer.id,
        :amount      => commerce_to_cents(@order.total_price),
        :description => "Payment Products: #{@order.products_list.join(', ')}",
        :currency    => commerce_current_currency
      )
      @order.set_meta("pay_stripe", params)
      mark_order_like_received(@order)
      redirect_to action: :index
    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to :back
    rescue => e
      flash[:error] = e.message
      redirect_to :back
    end
  end

  def pay_by_bank_transfer
    @order.set_meta("pay_bank_transfer", params[:details])
    mark_order_like_received(@order)
    redirect_to action: :index
  end

  def pay_by_authorize_net
    res = payment_pay_by_credit_card_authorize_net(@order, @payment)
    if res[:error].present?
      flash[:error] = res[:error]
      redirect_to :back
    else
      mark_order_like_received(@order)
      redirect_to action: :index
    end
  end

  def success_paypal
    @order = current_site.orders.find_by_slug(params[:order])
    @order.set_meta('pay_paypal', {token: params[:token], PayerID: params[:PayerID]})
    mark_order_like_received(@order)
    redirect_to action: :index
  end

  def cancel_paypal
    @order = current_site.orders.find_by_slug(params[:order])
    redirect_to action: :index
  end

  def pay_by_paypal
    billing_address = @order.get_meta("billing_address")
    details = @order.get_meta("details")
    ActiveMerchant::Billing::Base.mode = @payment.options[:paypal_sandbox].to_s.to_bool ? :test : :production
    paypal_options = {
      :login => @payment.options[:paypal_login],
      :password => @payment.options[:paypal_password],
      :signature => @payment.options[:paypal_signature]
    }
    @gateway = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
    @options = {
      brand_name: current_site.name,
      items: [{number: @order.slug, name: "Buy Products from #{current_site.the_title}: #{@order.products_list.join(',')}", amount: commerce_to_cents(@order.total_price)}],
      :order_id => @order.slug,
      :currency => current_site.currency_code,
      :email => details[:email],
      :billing_address => {:name => "#{billing_address[:first_name]} #{billing_address[:last_name]}",
                           :address1 => billing_address[:address1],
                           :address2 => billing_address[:address2],
                           :city => billing_address[:city],
                           :state => billing_address[:state],
                           :country => billing_address[:country],
                           :zip => billing_address[:zip]
      },
      :description => "Buy Products from #{current_site.the_title}: #{@order.products_list.join(',')}",
      :ip => request.remote_ip,
      :return_url => plugins_ecommerce_order_success_paypal_url(order: @order.slug),
      :cancel_return_url => plugins_ecommerce_order_cancel_paypal_url(order: @order.slug)
    }
    response = @gateway.setup_purchase(commerce_to_cents(@order.total_price.to_f), @options)
    redirect_to @gateway.redirect_url_for(response.token)
  end

  private
  def get_items(products)
    products.collect do |key, product|
      {
        :name => product[:product_title],
        :number => product[:product_id],
        :quantity => product[:qty],
        :amount => commerce_to_cents(product[:price].to_f),
      }
    end
  end

  def get_totals(payment)
    tax = payment[:tax_total].to_f
    subtotal = payment[:sub_total].to_f
    shipping = payment[:weight_price].to_f + payment[:sub_total].to_f
    total = subtotal + shipping
    return subtotal, shipping, total, tax
  end

  def commerce_to_cents(money)
    (money*100).round
  end

  def set_payment
    @payment = current_site.payment_methods.actives.where(id: params[:payment][:payment_id]).first
    @order = current_site.orders.find_by_slug(params[:order])
    @order.set_meta('payment_method_id', @payment.id)
  end

  def set_bread
    @ecommerce_bredcrumb << [t('plugins.ecommerce.messages.my_orders', default: 'My Orders'), url_for(action: :index)]
  end
end
