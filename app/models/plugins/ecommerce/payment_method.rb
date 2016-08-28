class Plugins::Ecommerce::PaymentMethod < CamaleonCms::TermTaxonomy
  default_scope { where(taxonomy: :ecommerce_payment_method) }
  belongs_to :site, :class_name => "CamaleonCms::Site", foreign_key: :parent_id

  scope :actives, -> {where(status: '1')}

  def method_text
    if options[:type] == 'cod'
      I18n.t 'plugin.ecommerce.method_cod'
    elsif options[:type] == 'paypal'
      I18n.t 'plugin.ecommerce.method_paypal'
    elsif options[:type] == 'credit_card'
      I18n.t 'plugin.ecommerce.method_credit_card'
    elsif options[:type] == 'bank_transfer'
      I18n.t 'plugin.ecommerce.method_bank_transfer'
    elsif options[:type] == 'authorize_net'
      I18n.t 'plugin.ecommerce.method_authorize_net'
    else
      'None'
    end
  end

end
