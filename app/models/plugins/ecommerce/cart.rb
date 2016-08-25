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

  has_many :product_items, foreign_key: :order_id, class_name: 'Plugins::Ecommerce::ProductItem', dependent: :destroy
  has_many :products, foreign_key: :order_id, through: :product_items

  belongs_to :site, :class_name => "CamaleonCms::Site", foreign_key: :site_id
  belongs_to :user, :class_name => "CamaleonCms::User", foreign_key: :user_id
  after_create :generate_slug

  def add_product(product, qty = 1, variation_id = nil)
    pi = product_items.where(product_id: product.id, variation_id: variation_id).first
    if pi.present?
      pi.update_column(:qty, qty)
    else
      pi = product_items.create(product_id: product.id, qty: qty, variation_id: variation_id)
    end
    pi
  end

  # return the product titles in array format
  def products_title
    product_items.map{|i| p=i.product.decorate; p.the_variation_title(i.variation_id) }.join(', ')
  end

  def items_total
    product_items.map{|item| item.qty }.inject{|sum,x| sum + x } || 0
  end

  # price of all products (no include taxes)
  def sub_total
    product_items.map{|item| product = item.product.decorate; (product.price(item.variation_id)) * item.qty }.inject{|sum,x| sum + x } || 0
  end

  def tax_total
    product_items.map{|item| product = item.product.decorate; (product.tax(item.variation_id)) * item.qty }.inject{|sum,x| sum + x } || 0
  end

  def weight_total
    product_items.map{|item| product = item.product.decorate; (product.weight(item.variation_id)) * item.qty }.inject{|sum,x| sum + x } || 0
  end

  # verify an return {error: (error code), discount: amount of discount} coupon for current cart
  # price: the total price including shipping price (used for free discount type)
  def discount_for(coupon_code, price = nil)
    coupon = site.coupons.find_by_slug(coupon_code)
    res = {error: '', discount: 0, coupon: coupon}
    if coupon.present?
      opts = coupon.options
      if coupon.expired?
        res[:error] = 'coupon_expired'
      elsif !coupon.active?
        res[:error] = 'inactive_coupon'
      elsif coupon.used_times_exceeded?
        res[:error] = 'times_exceeded'
      elsif !coupon.valid_min_price?(sub_total)
        res[:error] = 'required_minimum_price'
      else
        case opts[:discount_type]
          when 'free'
            res[:discount] = price || sub_total
          when 'free_ship'
            res[:discount] = total_shipping
          when 'percent'
            res[:discount] = sub_total * opts[:amount].to_f / 100
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
  def make_order!
    self.update_columns(kind: 'order', created_at: Time.current)
    site.orders.find(self.id)
  end

  def shipping_method
    Plugins::Ecommerce::ShippingMethod.find_by_id(self.shipping_method_id)
  end

  # return the total price without coupon price
  def total_to_pay_without_discounts
    sub_total + tax_total + total_shipping
  end
  alias_method :partial_total, :total_to_pay_without_discounts

  # include all costs and discounts
  def total_amount
    payment_amount = partial_total
    if self.coupon.present?
      res_coupon = self.discount_for(self.coupon, payment_amount)
      payment_amount = payment_amount - res_coupon[:discount] unless res_coupon[:error].present?
    end
    payment_amount < 0 ? 0 : payment_amount
  end

  # return total of discounts
  def total_discounts
    if self.coupon.present?
      self.discount_for(self.coupon, partial_total)[:discount] || 0
    else
      0
    end
  end

  # return the total price of shipping
  def total_shipping
    shipping_method.present? ? shipping_method.get_price_from_weight(weight_total) : 0
  end

  # set user in filter
  def self.set_user(user)
    user_id = defined?(user.id) ? user.id : user.to_i
    self.where(user_id: user_id)
  end

  # check if the price of the cart is 0, including prices for products, discounts, shipping
  def free_cart?
    total_amount <= 0
  end

  # return order object
  def make_paid!(status = 'paid')
    product_items.decorate.each do |item|
      p = item.product.decorate
      item.update_columns(cache_the_price: p.the_price(item.variation_id), cache_the_title: p.the_variation_title(item.variation_id), cache_the_tax: p.the_tax(item.variation_id), cache_the_sub_total: item.the_sub_total)
    end

    if self.coupon.present?
      res_coupon = self.discount_for(self.coupon, total_to_pay_without_discounts)
      unless res_coupon[:error].present?
        update_columns(the_coupon_amount: res_coupon[:coupon].decorate.the_amount, coupon_amount: res_coupon[:discount])
        res_coupon[:coupon].mark_as_used(user)
      end
    end
    c = self.decorate
    self.update_columns(status: status, paid_at: Time.current, amount: total_amount, cache_the_total: c.the_price, cache_the_sub_total: c.the_sub_total, cache_the_tax: c.the_tax_total, cache_the_weight: c.the_weight_total, cache_the_discounts: c.the_total_discounts, cache_the_shipping: c.the_total_shipping)
    make_order!
  end


  private
  def generate_slug
    self.update_column(:slug, "#{Time.current.to_i}-#{self.id}")
  end
end
