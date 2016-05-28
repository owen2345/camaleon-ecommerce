=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::Order < Plugins::Ecommerce::Cart
  self.table_name = 'plugins_ecommerce_orders'
  default_scope { where(kind: 'order') }

  def payment_method
    Plugins::Ecommerce::PaymentMethod.find_by_id(self.payment_method_id)
  end

  def payment
    payment = get_meta("payment")
    get_meta("pay_#{payment[:type]}".to_sym)
  end

  def canceled?
    status == 'canceled'
  end
  def unpaid?
    status == 'unpaid'
  end

  def paid?
    payment.present?
  end

  def total_price
    self.amount
  end

  # return the product titles in array format
  def products_list
    product_items.pluck(:the_title)
  end

  def make_paid!
    total_without_coupon = total_to_pay_without_discounts
    if self.coupon.present?
      res_coupon = self.discount_for(self.coupon, total_to_pay_without_discounts)
      unless res_coupon[:error].present?
        update_columns(the_coupon_amount: res[:coupon].decorate.the_amount, coupon_amount: res[:discount])
        res[:coupon].mark_as_used(user)
      end
    end
    self.update_columns(status: 'received', paid_at: Time.current, tax_total: the_tax_total, weight_price: the_weight_total, total: total_without_coupon, sub_total: the_amount_total, amount: total_to_pay, currency_code: site.decorate.currency_code)
  end
end
