class Plugins::Ecommerce::CouponDecorator < CamaleonCms::TermTaxonomyDecorator
  delegate_all

  # return the code of the coupon
  def the_code
    object.slug.to_s.upcase
  end

  # return humanized the amount/value of the coupon
  def the_amount
    opts = object.options
    case opts[:discount_type]
      when 'percent'
        "#{opts[:amount].to_f}%"
      when 'money'
        h.e_parse_price(opts[:amount].to_f)
      else
        I18n.t('plugins.ecommerce.table.free_shipping', default: 'Free Shipping')
    end
  end

  # return the html text status of the coupon
  def the_status
    opts = object.options
    if "#{opts[:expirate_date]} 23:59:59".to_datetime.to_i < Time.now.to_i
      "<span class='label label-danger'>#{I18n.t('plugins.ecommerce.table.expired')} </span>"
    elsif object.status.to_s.to_bool
      "<span class='label label-success'>#{I18n.t('plugins.ecommerce.active')} </span>"
    else
      "<span class='label label-default'>#{I18n.t('plugins.ecommerce.not_active')} </span>"
    end
  end
end
