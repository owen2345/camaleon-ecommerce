class Plugins::Ecommerce::Admin::OrdersController < Plugins::Ecommerce::AdminController
  before_action :set_order, except: [:index, :new] #, only: ['show', 'edit', 'update', 'destroy']
  before_action :set_order_bread

  def index
    @q = current_site.orders.order('received_at desc').ransack(params[:q])
    @orders = @q.result.paginate(:page => params[:page], :per_page => current_site.admin_per_page)
  end

  def show
    @order = @order.decorate
    add_breadcrumb("#{t('plugins.ecommerce.details_order', default: 'Order details')} - #{@order.slug}")
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
    hooks_run('plugin_ecommerce_before_update_order', @order)
    @order.set_meta("billing_address", params[:order][:billing_address])
    @order.set_meta("shipping_address", params[:order][:shipping_address])
    @order.set_metas(params[:metas])
    @order.update(params.require(:plugins_ecommerce_order).permit(:shipped_at))
    hooks_run('plugin_ecommerce_after_destroy_order', @order)
    flash[:notice] = "#{t('plugins.ecommerce.message.order_updated', default: 'Order Updated')}"
    redirect_to action: :show, id: params[:id]
  end

  def destroy
    hooks_run('plugin_ecommerce_before_destroy_order', @order)
    if @order.destroy
      flash[:notice] = "#{t('plugins.ecommerce.message.order_destroyed', default: 'Order Destroyed')}"
    else
      flash[:error] = "#{t('plugins.ecommerce.message.order_no_destroyed', default: 'Occurred some problems destroying the order')}"
    end
    hooks_run('plugin_ecommerce_after_destroy_order', @order)
    redirect_to action: :index
  end

  # accepted order
  def mark_accepted
    r = {order: @order}; hooks_run('plugin_ecommerce_before_accepted_order', r)
    @order.accepted!
    commerce_order_send_mail(@order, 'email_order_accepted')
    message = "#{t('plugins.ecommerce.message.order_accepted', default: 'Order Accepted')}"
    r = {order: @order, message: message}; hooks_run('plugin_ecommerce_after_accepted_order', r)
    flash[:notice] = r[:message]
    redirect_to action: :index
  end

  def mark_bank_confirmed
    if @order.on_delivery_pending?
      hooks_run('plugin_ecommerce_before_on_delivery_order', @order)
      @order.on_delivery_confirmed!
      commerce_order_send_mail(@order, 'email_order_confirmed_on_delivery')
      flash[:notice] = "#{t('plugins.ecommerce.message.order_on_delivery_confirmed', default: 'Payment on Delivery Confirmed')}"
      hooks_run('plugin_ecommerce_after_on_delivery_order', @order)
    else
      hooks_run('plugin_ecommerce_before_bank_confirm_order', @order)
      @order.bank_confirmed!
      commerce_order_send_mail(@order, 'email_order_confirmed_bank')
      flash[:notice] = "#{t('plugins.ecommerce.message.order_bank_confirmed', default: 'Pay Bank Confirmed')}"
      hooks_run('plugin_ecommerce_after_bank_confirm_order', @order)
    end
    redirect_to action: :index
  end

  # shipped order
  def mark_shipped
    hooks_run('plugin_ecommerce_before_shipped_order', @order)
    @order.shipped!(params[:consignment_number])
    commerce_order_send_mail(@order, 'email_order_shipped')
    flash[:notice] = "#{t('plugins.ecommerce.message.order_shipped', default: 'Order Shipped')}"
    hooks_run('plugin_ecommerce_after_shipped_order', @order)
    redirect_to action: :index
  end

  def mark_canceled
    hooks_run('plugin_ecommerce_before_canceled_order', @order)
    @order.canceled!
    @order.set_meta('description', params[:description])
    commerce_order_send_mail(@order, 'email_order_cancelled')
    flash[:notice] = "#{t('plugins.ecommerce.message.order_canceled', default: 'Order canceled')}"
    hooks_run('plugin_ecommerce_after_canceled_order', @order)
    redirect_to action: :index
  end

  def resend_email
    case @order.status
      when 'paid', 'bank_pending', 'on_delivery'
        commerce_order_send_mail(@order)
      when 'shipped'
        commerce_order_send_mail(@order, 'email_order_shipped')
      when 'canceled'
        commerce_order_send_mail(@order, 'email_order_cancelled')
      else
        flash[:error] = "#{t('plugins.ecommerce.message.unknown_status', default: 'Unknown Status')}"
        redirect_to action: :index
        return
    end
    flash[:notice] = "#{t('plugins.ecommerce.message.order_email_resent', default: 'Order Email Resent')}"
    redirect_to action: :index
  end

  private
  def set_order
    @order = current_site.orders.find_by_slug(params[:id] || params[:order_id]).decorate
  end

  def set_order_bread
    add_breadcrumb I18n.t("plugins.ecommerce.orders", default: 'Orders'), admin_plugins_ecommerce_orders_path
  end

end
