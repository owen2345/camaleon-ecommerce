class Plugins::Ecommerce::Admin::OrdersController < Plugins::Ecommerce::AdminController
  before_action :set_order, except: [:index, :new] #, only: ['show', 'edit', 'update', 'destroy']
  before_action :set_order_bread

  def index
    orders = current_site.orders
    if params[:q].present?
      orders = orders.where("#{Plugins::Ecommerce::Order.table_name}.slug LIKE ?", "%#{params[:q]}%")
    end
    if params[:c].present?
      orders = orders.joins(:user).where("#{Cama::User.table_name}.first_name LIKE ? OR #{Cama::User.table_name}.last_name LIKE ?", "%#{params[:c]}%", "%#{params[:c]}%")
    end
    if params[:e].present?
      orders = orders.joins(:user).where("#{Cama::User.table_name}.email LIKE ?", "%#{params[:e]}%")
    end
    if params[:s].present?
      orders = orders.where(status: params[:s].split('|'))
    end
    orders = orders.order('received_at desc')
    @orders = orders.paginate(:page => params[:page], :per_page => current_site.admin_per_page)
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
    @order.set_meta("billing_address", params[:order][:billing_address])
    @order.set_meta("shipping_address", params[:order][:shipping_address])
    @order.set_metas(params[:metas])
    @order.update(params.require(:plugins_ecommerce_order).permit(:shipped_at))
    flash[:notice] = "#{t('plugins.ecommerce.message.order_updated', default: 'Order Updated')}"
    redirect_to action: :show, id: params[:id]
  end

  def destroy
    if @order.destroy
      flash[:notice] = "#{t('plugins.ecommerce.message.order_destroyed', default: 'Order Destroyed')}"
    else
      flash[:error] = "#{t('plugins.ecommerce.message.order_no_destroyed', default: 'Occurred some problems destroying the order')}"
    end
    redirect_to action: :index
  end

  # accepted order
  def mark_accepted
    r = {order: @order}; hooks_run('plugin_ecommerce_before_accepted_order', r)
    @order.accepted!
    message = "#{t('plugins.ecommerce.message.order_accepted', default: 'Order Accepted')}"
    r = {order: @order, message: message}; hooks_run('plugin_ecommerce_after_accepted_order', r)
    flash[:notice] = r[:message]
    redirect_to action: :index
  end

  def mark_bank_confirmed
    if @order.on_delivery_pending?
      @order.on_delivery_confirmed!
      flash[:notice] = "#{t('plugins.ecommerce.message.order_on_delivery_confirmed', default: 'Payment on Delivery Confirmed')}"
      commerce_send_order_received_email(@order)
    else
      @order.bank_confirmed!
      flash[:notice] = "#{t('plugins.ecommerce.message.order_bank_confirmed', default: 'Pay Bank Confirmed')}"
      commerce_send_order_received_email(@order, true)
    end
    redirect_to action: :index
  end

  # shipped order
  def mark_shipped
    @order.shipped!(params[:consignment_number])
    cama_send_email(@order.user.email, t('plugins.ecommerce.mail.order_shipped.subject'), {template_name: 'order_shipped', extra_data: {order: @order, consignment_number: params[:consignment_number]}})
    flash[:notice] = "#{t('plugins.ecommerce.message.order_shipped', default: 'Order Shipped')}"
    redirect_to action: :index
  end

  def mark_canceled
    @order.canceled!
    @order.set_meta('description', params[:description])
    cama_send_email(@order.user.email, t('plugins.ecommerce.mail.order_canceled.subject'), {template_name: 'order_canceled', extra_data: {order: @order}, description: params[:description]})
    flash[:notice] = "#{t('plugins.ecommerce.message.order_canceled', default: 'Order canceled')}"
    redirect_to action: :index
  end

  private
  def set_order
    @order = current_site.orders.find_by_slug(params[:id] || params[:order_id])
  end

  def set_order_bread
    add_breadcrumb I18n.t("plugins.ecommerce.orders", default: 'Orders'), admin_plugins_ecommerce_orders_path
  end

end
