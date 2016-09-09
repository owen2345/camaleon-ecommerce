class Plugins::Ecommerce::UtilService
  def self.ecommerce_money_to_cents(money)
    (money*100).round
  end
end
