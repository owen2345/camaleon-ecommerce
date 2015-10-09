module Plugins::Ecommerce::EcommercePaymentHelper


  def payment_pay_by_credit_card_authorize_net(order)
    payment = order.meta[:payment]
    billing_address = order.meta[:billing_address]
    details = order.meta[:details]
    payment_method = current_site.payment_methods.find(payment[:payment_id])
    amount = to_cents(payment[:amount].to_f)

    params = {
      :order_id => order.slug,
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
      :description => 'Buy Products',
      :ip => request.remote_ip
    }

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

    if credit_card.valid?
      gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(authorize_net_options)
      response = gateway.purchase(amount, credit_card, params)
      if response.success?
        mark_order_received(order, @params)
        return {success: 'Paid Correct'}
      else
        return {error: response.message}
      end
    else
      return {error: 'Credit Card Invalid'}
    end

  end


  private

  def mark_order_received(order, params)
    order.update({status: 'received'})
    order.details.update({received_at: Time.now})
    order.set_meta('pay_authorize_net', params)
  end

end
