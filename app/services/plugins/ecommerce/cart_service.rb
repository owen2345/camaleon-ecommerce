class Plugins::Ecommerce::CartService
  def initialize(site, cart)
    @site = site
    @cart = cart
  end
  
  attr_reader :site, :cart
  
  def pay_with_authorize_net(options={})
    payment_method = options[:payment_method] || get_payment_method('authorize_net')
    billing_address = cart.get_meta("billing_address")
    details = cart.get_meta("details")
    amount = Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(cart.total_amount)
    payment_params = {
      :order_id => cart.slug,
      :currency => site.currency_code,
      :email => cart.user.email,
      :billing_address => {:name => "#{cart.user.fullname}",
                           :address1 => billing_address[:address1],
                           :address2 => billing_address[:address2],
                           :city => billing_address[:city],
                           :state => billing_address[:state],
                           :country => billing_address[:country],
                           :zip => billing_address[:zip]
      },
      :description => 'Buy Products',
      :ip => request.remote_ip
    }
    
    if options[:ip]
      payment_params[:ip] = options[:ip]
    end

    authorize_net_options = {
      :login => payment_method.options[:authorize_net_login_id],
      :password => payment_method.options[:authorize_net_transaction_key]
    }

    ActiveMerchant::Billing::Base.mode = payment_method.options[:authorize_net_sandbox].to_s.to_bool ? :test : :production

    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :first_name => params[:firstName],
      :last_name => params[:lastName],
      :number => params[:cardNumber],
      :month => params[:expMonth],
      :year => "20#{params[:expYear]}",
      :verification_value => params[:cvCode]
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
    payment_method = options[:payment_method] || get_payment_method('paypal')
    billing_address = cart.get_meta("billing_address")
    ActiveMerchant::Billing::Base.mode = payment_method.options[:paypal_sandbox].to_s.to_bool ? :test : :production
    paypal_options = {
      :login => payment_method.options[:paypal_login],
      :password => payment_method.options[:paypal_password],
      :signature => payment_method.options[:paypal_signature]
    }
    gateway = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
    amount_in_cents = Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(cart.total_amount)
    gateway_request = {
      brand_name: site.name,
      items: [{
        number: cart.slug,
        name: "Buy Products from #{site.the_title}: #{cart.products_title}",
        amount: amount_in_cents,
      }],
      :order_id => cart.slug,
      :currency => site.currency_code,
      :email => cart.user.email,
      :billing_address => {:name => "#{billing_address[:first_name]} #{billing_address[:last_name]}",
                           :address1 => billing_address[:address1],
                           :address2 => billing_address[:address2],
                           :city => billing_address[:city],
                           :state => billing_address[:state],
                           :country => billing_address[:country],
                           :zip => billing_address[:zip]
      },
      :description => "Buy Products from #{site.the_title}: #{cart.total_amount}",
      :ip => request.remote_ip,
      :return_url => plugins_ecommerce_checkout_success_paypal_url(order: @cart.slug),
      :cancel_return_url => plugins_ecommerce_checkout_cancel_paypal_url(order: @cart.slug)
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
    payment_method = options[:payment_method] || get_payment_method('stripe')
    Stripe.api_key = payment_method.options[:stripe_id]
    customer = Stripe::Customer.create(
      :email => params[:email], :source  => params[:stripe_token])
    amount_in_cents = Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(cart.total_amount)
    begin
      charge = Stripe::Charge.create(
        :customer    => customer.id,
        :amount      => amount_in_cents,
        :description => "Payment Products: #{cart.products_title}",
        :currency    => site_currency,
      )
      cart.set_meta("payment_data", params)
      {}
    rescue Stripe::CardError => e
      {error: e.message, payment_error: true}
    rescue => e
      {error: e.message}
    end
  end
  
  private
  
  def site_currency
    site.get_meta("_setting_ecommerce", {})[:current_unit] || 'USD'
  end
  
  def get_payment_method(type)
    payment_method = site.payment_methods.actives.detect do |payment_method|
      payment_method.get_option('type') == type
    end
    if payment_method.nil?
      raise ArgumentError, "Payment method #{type} is not found"
    end
    payment_method
  end
end
