class Plugins::Ecommerce::Front::OrdersController < Plugins::Ecommerce::FrontController
  before_action :commerce_authenticate
  before_action :set_bread
  def index
    @orders = current_site.orders.set_user(cama_current_user).decorate
    render "index"
  end

  def show
    @order = current_site.orders.set_user(cama_current_user).find_by_slug(params[:order]).try(:decorate)
    return redirect_to(url_for(action: :index), error: t('plugins.ecommerce.messages.order_not_found', default: "Order not found", order: params[:order])) unless @order.present?
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.detail_order', default: "Detail order: #%{order}", order: params[:order])]
  end

  private
  def set_bread
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.my_orders', default: 'My Orders'), url_for(action: :index)]
  end
end
