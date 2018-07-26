class Plugins::Ecommerce::Cart < ActiveRecord::Base
  self.table_name = 'plugins_ecommerce_orders'
  default_scope { where(kind: 'cart') }
  include CamaleonCms::Metas

  has_many :product_items, foreign_key: :order_id, class_name: 'Plugins::Ecommerce::ProductItem', dependent: :destroy
  has_many :products, foreign_key: :order_id, through: :product_items

  belongs_to :site, :class_name => "CamaleonCms::Site", foreign_key: :site_id
  belongs_to :user, :class_name => "User", foreign_key: :user_id
  belongs_to :shipping_method, class_name: 'Plugins::Ecommerce::ShippingMethod'
  scope :active_cart, ->{ where("#{Plugins::Ecommerce::Cart.table_name}.updated_at >= ?", 24.hours.ago) }

  after_create :generate_slug

  # status: bank_pending => pending of verification for bank transfer orders
  #         paid => paid by some method
  #         canceled => canceled order
  #         shipped => shipped status

  def payment_method
    @_cama_cache_payment_method ||= Plugins::Ecommerce::PaymentMethod.find_by_id(get_meta('payment_method_id', self.payment_method_id))
  end

  def add_product(product, qty = 1, variation_id = nil)
    pi = product_items.where(product_id: product.id, variation_id: variation_id).first
    if pi.present?
      pi.update_column(:qty, qty)
    else
      pi = product_items.create(product_id: product.id, qty: qty, variation_id: variation_id)
    end
    pi
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
    res = {error: '', discount: 0, coupon: nil}
    return res if coupon_code.blank?
    coupon = site.coupons.find_by_slug(coupon_code)
    res[:coupon] = coupon
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
          when 'free_ship', 'free'
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

  def prepare_to_pay
    self.class.transaction do
      self.update_columns(
        status: 'qtys_taken',
      )
      self.product_items.decorate.each{|p_item| p_item.decrement_qty! }
    end
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
    if decorate.contains_physical_products?
      shipping_method.present? ? shipping_method.get_price_from_weight(weight_total) : 0
    else
      0
    end
  end

  # set user in filter (filter carts by user_id or cookie_id)
  # cookie_id is used for public users who are buying without login
  def self.set_user(user)
    defined?(user.id) ? self.where(user_id: user.id) : self.where(visitor_key: user)
  end

  # move current cart from public user into existent user
  def change_user(user)
    update_columns(user_id: user.id, visitor_key: nil)
  end

  # check if the price of the cart is 0, including prices for products, discounts, shipping
  def free_cart?
    total_amount <= 0
  end

  def update_amounts
    product_items.decorate.each do |item|
      p = item.product.decorate
      item.update_columns(
        cache_the_price: p.the_price(item.variation_id),
        cache_the_title: p.the_variation_title(item.variation_id),
        cache_the_tax: p.the_tax(item.variation_id),
        cache_the_sub_total: item.the_sub_total,
      )
    end

    if self.coupon.present?
      res_coupon = self.discount_for(self.coupon, total_to_pay_without_discounts)
      unless res_coupon[:error].present?
        update_columns(the_coupon_amount: res_coupon[:coupon].decorate.the_amount)
        res_coupon[:coupon].mark_as_used(user)
      end
    end
    c = self.decorate
    self.update_columns(
      amount: total_amount,
      cache_the_total: c.the_price,
      cache_the_sub_total: c.the_sub_total,
      cache_the_tax: c.the_tax_total,
      cache_the_weight: c.the_weight_total,
      cache_the_discounts: c.the_total_discounts,
      cache_the_shipping: c.the_total_shipping,
    )
  end

  # return the gateway for paypal transactions
  def paypal_gateway
    ActiveMerchant::Billing::Base.mode = payment_method.options[:paypal_sandbox].to_s.to_bool ? :test : :production
    paypal_options = {
      login: payment_method.options[:paypal_login],
      password: payment_method.options[:paypal_password],
      signature: payment_method.options[:paypal_signature]
    }
    ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
  end


  private
  def generate_slug
    self.update_column(:slug, "#{Time.current.to_i}-#{self.id}")
  end
end
