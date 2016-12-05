class Plugins::Ecommerce::PaymentMethod < CamaleonCms::TermTaxonomy
  default_scope { where(taxonomy: :ecommerce_payment_method) }
  belongs_to :site, :class_name => "CamaleonCms::Site", foreign_key: :parent_id

  scope :actives, -> {where(status: '1')}

  def method_text
    if options[:type] == 'paypal'
      I18n.t 'plugins.ecommerce.by_paypal', default: 'Paypal'
    elsif options[:type] == 'credit_card'
      I18n.t 'plugins.ecommerce.method_credit_card'
    elsif options[:type] == 'authorize_net'
      I18n.t 'plugins.ecommerce.by_authorize_net', default: 'By credit card (Authorize.net)'
    elsif options[:type] == 'on_delivery'
      I18n.t 'plugins.ecommerce.by_on_delivery'
    elsif options[:type] == 'stripe'
      I18n.t 'plugins.ecommerce.by_stripe', default: 'By Stripe'
    elsif options[:type] == 'bank_transfer'
      I18n.t 'plugins.ecommerce.by_bank_transfer', default: 'Payment on Delivery'
    else
      'None'
    end
  end

end
