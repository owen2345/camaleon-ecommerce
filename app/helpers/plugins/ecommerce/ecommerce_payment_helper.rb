module Plugins::Ecommerce::EcommercePaymentHelper
  def commerce_to_cents(money)
    Plugins::Ecommerce::UtilService.ecommerce_money_to_cents(money)
  end

end
