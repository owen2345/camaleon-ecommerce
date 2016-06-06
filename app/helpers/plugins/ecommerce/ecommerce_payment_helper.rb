module Plugins::Ecommerce::EcommercePaymentHelper
  include Plugins::Ecommerce::EcommerceHelper

  def payment_pay_by_credit_card_authorize_net(order, payment_method)
    billing_address = order.get_meta("billing_address")
    details = order.get_meta("details")
    amount = commerce_to_cents(order.total_amount)
    payment_params = {
      :order_id => order.slug,
      :currency => current_site.currency_code,
      :email => order.user.email,
      :billing_address => {:name => "#{order.user.fullname}",
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

    authorize_net_options = {
      :login => payment_method.options[:authorize_net_login_id],
      :password => payment_method.options[:authorize_net_transaction_key]
    }

    ActiveMerchant::Billing::Base.mode = payment_method.options[:authorize_net_sandbox].to_s.to_bool ? :test : :production

    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :first_name => order.user.first_name,
      :last_name => order.user.last_name,
      :number => params[:cardNumber],
      :month => params[:expMonth],
      :year => "20#{params[:expYear]}",
      :verification_value => params[:cvCode]
    )
    if credit_card.validate.empty?
      gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(authorize_net_options)
      response = gateway.purchase(amount, credit_card, payment_params)
      if response.success?
        order.set_meta('pay_authorize_net', payment_params)
        return {}
      else
        return {error: response.message}
      end
    else
      return {error: credit_card.validate.map{|k, v| "#{k}: #{v.join(', ')}"}.join('<br>')}
    end
  end

  def commerce_to_cents(money)
    (money*100).round
  end

  def commerce_current_currency
    current_site.get_meta("_setting_ecommerce", {})[:current_unit] || 'USD'
  end

end
