class Plugins::Ecommerce::SiteService
  def initialize(site)
    @site = site
  end
  
  attr_reader :site
  
  def currency
    site.get_meta("_setting_ecommerce", {})[:current_unit] || 'USD'
  end
  
  def payment_method(type)
    payment_method = site.payment_methods.actives.detect do |payment_method|
      payment_method.get_option('type') == type
    end
    if payment_method.nil?
      raise ArgumentError, "Payment method #{type} is not found"
    end
    payment_method
  end
end
