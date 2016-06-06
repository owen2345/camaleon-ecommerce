=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::Admin::OrdersController < Plugins::Ecommerce::AdminController
  before_action :set_order, except: [:index, :new] #, only: ['show', 'edit', 'update', 'destroy']
  before_action :set_order_bread

  def index
    orders = current_site.orders
    if params[:q].present?
      orders = orders.where(slug: params[:q])
    end
    if params[:c].present?
      orders = orders.joins(:details).where("plugins_order_details.customer LIKE ?", "%#{params[:c]}%")
    end
    if params[:e].present?
      orders = orders.joins(:details).where("plugins_order_details.email LIKE ?", "%#{params[:e]}%")
    end
    if params[:p].present?
      orders = orders.joins(:details).where("plugins_order_details.phone LIKE ?", "%#{params[:p]}%")
    end
    if params[:s].present?
      orders = orders.where(status: params[:s])
    end
    @orders = orders.paginate(:page => params[:page], :per_page => current_site.admin_per_page)
  end

  def show
    @order = @order.decorate
    add_breadcrumb("#{t('plugin.ecommerce.details_order', default: 'Order details')} - #{@order.slug}")
  end

  def new
    @order = current_site.orders.new
    render 'form'
  end

  def edit
    add_breadcrumb("#{t('camaleon_cms.admin.button.edit', default: 'Edit')}")
    render 'form'
  end

  def update
    @order.set_meta("billing_address", params[:order][:billing_address])
    @order.set_meta("shipping_address", params[:order][:shipping_address])
    @order.set_metas(params[:metas])
    flash[:notice] = "#{t('plugin.ecommerce.message.order_updated', default: 'Order Updated')}"
    redirect_to action: :show, id: params[:id]
  end

  def destroy
    if @order.destroy
      flash[:notice] = "#{t('plugin.ecommerce.message.order_destroyed', default: 'Order Destroyed')}"
    else
      flash[:error] = "#{t('plugin.ecommerce.message.order_no_destroyed', default: 'Occurred some problems destroying the order')}"
    end
    redirect_to action: :index
  end

  # accepted order
  def mark_accepted
    @order.accepted!
    r = {order: @order}; hooks_run('plugin_ecommerce_before_accepted_order', r)
    message = "#{t('plugin.ecommerce.message.order_accepted', default: 'Order Accepted')}"
    r = {order: @order, message: message}; hooks_run('plugin_ecommerce_after_accepted_order', r)
    flash[:notice] = r[:message]
    redirect_to action: :index
  end

  def mark_bank_confirmed
    @order.bank_confirmed!
    commerce_send_order_received_email(@order, true)
    flash[:notice] = "#{t('plugin.ecommerce.message.order_bank_confirmed', default: 'Pay Bank Confirmed')}"
    redirect_to action: :index
  end

  # shipped order
  def mark_shipped
    @order.shipped!(params[:consignment_number])
    cama_send_email(@order.user.email, t('plugin.ecommerce.mail.order_shipped.subject'), {template_name: 'order_shipped', extra_data: {order: @order, consignment_number: params[:consignment_number]}})
    flash[:notice] = "#{t('plugin.ecommerce.message.order_shipped', default: 'Order Shipped')}"
    redirect_to action: :index
  end

  def mark_canceled
    @order.canceled!
    @order.set_meta('description', params[:description])
    cama_send_email(@order.user.email, t('plugin.ecommerce.mail.order_canceled.subject'), {template_name: 'order_canceled', extra_data: {order: @order}, description: params[:description]})
    flash[:notice] = "#{t('plugin.ecommerce.message.order_canceled', default: 'Order canceled')}"
    redirect_to action: :index
  end

  private
  def set_order
    @order = current_site.orders.find_by_slug(params[:id] || params[:order_id])
  end

  def set_order_bread
    add_breadcrumb I18n.t("plugin.ecommerce.orders", default: 'Orders'), admin_plugins_ecommerce_orders_path
  end

end
