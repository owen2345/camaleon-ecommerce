module Plugins::Ecommerce::EcommercePaymentHelper
  include Plugins::Ecommerce::EcommerceHelper

  def commerce_to_cents(money)
    Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(money)
  end

end
