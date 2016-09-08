module Plugins::Ecommerce::EcommercePaymentHelper
  include Plugins::Ecommerce::EcommerceHelper

  def payment_pay_by_credit_card_authorize_net(cart, payment_method)
    Plugins::Ecommerce::CartService.new(current_site, cart).
      pay_with_authorize_net(payment_method, ip: request.remote_ip)
  end

  def commerce_to_cents(money)
    Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(money)
  end

end
