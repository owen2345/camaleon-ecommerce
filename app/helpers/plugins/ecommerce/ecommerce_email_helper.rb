module Plugins::Ecommerce::EcommerceEmailHelper
  include CamaleonCms::EmailHelper

  def send_order_received_email(order)
    extra_data = {
      :fullname => order.customer.fullname,
      :order_slug => order.slug,
      :order_url => plugins_ecommerce_order_show_url(order: order.slug),
      :billing_information => order.get_meta('billing_address'),
      :shipping_address => order.get_meta('shipping_address'),
      :subtotal => order.get_meta("payment")[:total],
      :total_cost => order.get_meta("payment")[:amount],
      :order => order
    }
    send_email(order.customer.email, t('plugin.ecommerce.email.order_received.subject'), '', nil, [], 'order_received', nil, extra_data)
  end

  def send_order_received_admin_notice(order)
    extra_data = {
      :fullname => order.customer.fullname,
      :order_slug => order.slug,
      :order_url => plugins_ecommerce_order_show_url(order: order.slug),
      :billing_information => order.get_meta('billing_address'),
      :shipping_address => order.get_meta('shipping_address'),
      :subtotal => order.get_meta("payment")[:total],
      :total_cost => order.get_meta("payment")[:amount],
      :order => order
    }

    users = current_site.users.where(:role => :admin)
    users.each do |user|
      extra_data[:admin] = user
      send_email(user.email, t('plugin.ecommerce.email.order_received_admin.subject'), '', nil, [], 'order_received_admin', nil, extra_data)
    end
  end

  def send_recovery_cart_email(order)
    extra_data = {
      :fullname => order.customer.fullname,
      :order => order
    }
    send_email(order.customer.email, t('plugin.ecommerce.email.recovery_cart.subject'), '', nil, [], 'recovery_cart', nil, extra_data)
    Rails.logger.info "Send recovery to #{order.customer.email} with order #{order.slug}"
  end

end
