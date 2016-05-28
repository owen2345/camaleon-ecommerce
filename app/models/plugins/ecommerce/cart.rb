=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::Cart < ActiveRecord::Base
  self.table_name = 'plugins_ecommerce_orders'
  default_scope { where(kind: 'cart') }
  include CamaleonCms::Metas
  include CamaleonCms::CustomFieldsRead

  has_many :product_items, foreign_key: :order_id, class_name: 'Plugins::Ecommerce::ProductItems', dependent: :destroy
  has_many :products, foreign_key: :order_id, through: :product_items

  belongs_to :site, :class_name => "CamaleonCms::Site", foreign_key: :site_id
  belongs_to :user, :class_name => "CamaleonCms::User", foreign_key: :user_id

  def add_product(product, qty = 1)
    pi = product_items.where(product_id: product.id).first
    if pi.present?
      pi.update_column(:qty, pi.qty + qty)
    else
      product_items.create(product_id: product.id, qty: qty, the_price: product.the_price, the_title: product.the_title, the_tax: product.the_tax)
    end
  end

  def remove_product(product_id)
    product_items.where(product_id: product_id).destroy_all
  end

  def the_items_count
    product_items.map{|item| item.qty }.inject{|sum,x| sum + x }
  end

  # return the total price of the cart that includes products price + taxes (not included shipping price)
  def the_amount_total
    product_items.map{|item| product = item.product.decorate; (product.price + product.tax) * item.qty }.inject{|sum,x| sum + x } || 0
  end

  def the_tax_total
    product_items.map{|item| product = item.product.decorate; (product.tax) * item.qty }.inject{|sum,x| sum + x } || 0
  end

  def the_weight_total
    product_items.map{|item| product = item.product.decorate; (product.weight) * item.qty }.inject{|sum,x| sum + x } || 0
  end

  # return the price of current cart ($10) not including shipping price
  def the_price(shipping_price = 0)
    "#{self.site.decorate.current_unit}#{sprintf('%.2f', the_amount_total + shipping_price)}"
  end

  # verify an return {error: (error code), discount: amount of discount} coupon for current cart
  # price: the total price including shipping price (used for free discount type)
  def discount_for(coupon_code, price = nil)
    coupon = site.coupons.find_by_slug(coupon_code) rescue nil
    res = {error: '', discount: 0, coupon: coupon}
    if coupon.present?
      opts = coupon.options
      if coupon.expired?
        res[:error] = 'coupon_expired'
      elsif !coupon.active?
        res[:error] = 'inactive_coupon'
      elsif coupon.used_times_exceeded?
        res[:error] = 'times_exceeded'
      elsif !coupon.valid_min_price?(the_amount_total)
        res[:error] = 'required_minimum_price'
      else
        case opts[:discount_type]
          when 'free_ship'
            res[:discount] = price || the_amount_total
          when 'percent'
            res[:discount] = the_amount_total * opts[:amount].to_f / 100
          when 'money'
            res[:discount] = opts[:amount].to_f
        end
      end
    else
      res[:error] = 'coupon_not_found'
    end
    res
  end

  # convert into order current cart
  def make_order
    self.update_column(:kind, 'order')
    site.orders.find(self.id)
  end

  def shipping_method
    Plugins::Ecommerce::ShippingMethod.find_by_id(self.shipping_method_id)
  end

  # return the total price without coupon price
  def total_to_pay_without_discounts
    weight_price = shipping_method.present? ? shipping_method.get_price_from_weight(the_weight_total) : 0
    the_amount_total + the_tax_total + weight_price
  end

  # include all costs and discounts
  def total_to_pay
    payment_amount = total_to_pay_without_coupon
    if self.coupon.present?
      res_coupon = self.discount_for(self.coupon, payment_amount)
      payment_amount = payment_amount - res[:discount] unless res_coupon[:error].present?
    end
    payment_amount < 0 ? 0 : payment_amount
  end

  # set user in filter
  def self.set_user(user)
    user_id = defined?(user.id) ? user.id : user.to_i
    self.where(user_id: user_id)
  end
end
