class Plugins::Ecommerce::CartService
  def initialize(site, cart)
    @site = site
    @cart = cart
  end

  attr_reader :site, :cart

  def pay_with_authorize_net(options={})
    payment_method = options[:payment_method] || site_service.payment_method('authorize_net')
    billing_address = cart.get_meta("billing_address")
    details = cart.get_meta("details")
    amount = Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(cart.total_amount)
    payment_params = {
      order_id: cart.slug,
      currency: site.currency_code,
      email: cart.user.email,
      billing_address: {name: "#{cart.user.fullname}",
                           address1: billing_address[:address1],
                           address2: billing_address[:address2],
                           city: billing_address[:city],
                           state: billing_address[:state],
                           country: billing_address[:country],
                           zip: billing_address[:zip]
      },
      description: 'Buy Products',
      ip: options[:ip]
    }

    if options[:ip]
      payment_params[:ip] = options[:ip]
    end

    authorize_net_options = {
      login: payment_method.options[:authorize_net_login_id],
      password: payment_method.options[:authorize_net_transaction_key]
    }

    ActiveMerchant::Billing::Base.mode = payment_method.options[:authorize_net_sandbox].to_s.to_bool ? :test : :production

    credit_card = ActiveMerchant::Billing::CreditCard.new(
      first_name: options[:first_name],
      last_name: options[:last_name],
      number: options[:number],
      month: options[:exp_month],
      year: "20#{options[:exp_year]}",
      verification_value: options[:cvc]
    )
    if credit_card.validate.empty?
      gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(authorize_net_options)
      response = gateway.purchase(amount, credit_card, payment_params)
      if response.success?
        cart.set_meta('pay_authorize_net', payment_params)
        return {}
      else
        return {error: response.message}
      end
    else
      return {error: credit_card.validate.map{|k, v| "#{k}: #{v.join(', ')}"}.join('<br>')}
    end
  end

  def pay_with_paypal(options={})
    billing_address = cart.get_meta("billing_address")
    gateway = cart.paypal_gateway
    amount_in_cents = Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(cart.total_amount)
    gateway_request = {
      brand_name: site.name,
      items: [{
        number: cart.slug,
        name: "Buy Products from #{site.the_title}: #{cart.products_title}",
        amount: amount_in_cents,
      }],
      order_id: cart.slug,
      currency: site.currency_code,
      email: cart.user.email,
      billing_address: {name: "#{billing_address[:first_name]} #{billing_address[:last_name]}",
                           address1: billing_address[:address1],
                           address2: billing_address[:address2],
                           city: billing_address[:city],
                           state: billing_address[:state],
                           country: billing_address[:country],
                           zip: billing_address[:zip]
      },
      description: "Buy Products from #{site.the_title}: #{cart.total_amount}",
      ip: options[:ip],
      return_url: options[:return_url],
      cancel_return_url: options[:cancel_return_url]
    }

    if options[:ip]
      gateway_request[:ip] = options[:ip]
    end

    response = gateway.setup_purchase(amount_in_cents, gateway_request)
    # TODO handle errors
    {redirect_url: gateway.redirect_url_for(response.token)}
  end

  def pay_with_stripe(options)
    require 'stripe'
    payment_method = options[:payment_method] || site_service.payment_method('stripe')
    Stripe.api_key = payment_method.options[:stripe_id]
    customer = Stripe::Customer.create(
      email: options[:email], source: options[:stripe_token])
    amount_in_cents = Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(cart.total_amount)
    begin
      charge = Stripe::Charge.create(
        customer: customer.id,
        amount: amount_in_cents,
        description: "Payment Products: #{cart.products_title}",
        currency: site_service.currency,
      )
      payment_data = {
        email: options[:email],
        customer: customer.id,
        charge: charge.id,
      }
      cart.set_meta("payment_data", payment_data)
      {}
    rescue Stripe::CardError => e
      {error: e.message, payment_error: true}
    rescue => e
      {error: e.message}
    end
  end

  def convert_to_order(status = 'paid')
    Plugins::Ecommerce::Cart.transaction do
      cart.prepare_to_pay
      cart.update_amounts
      cart.mark_paid(status)
      cart.convert_to_order
    end
  end

  private

  def site_service
    @site_service ||= Plugins::Ecommerce::SiteService.new(site)
  end
end
