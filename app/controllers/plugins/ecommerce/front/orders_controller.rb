class Plugins::Ecommerce::Front::OrdersController < Plugins::Ecommerce::FrontController
  before_action :commerce_authenticate
  before_action :set_bread
  def index
    @orders = current_site.orders.set_user(current_user).decorate
    render "index"
  end

  def show
    @order = current_site.orders.find_by_slug(params[:order]).decorate
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.detail_order', default: "Detail order: #%{order}", order: params[:order])]
  end



  private
  def set_bread
    @ecommerce_breadcrumb << [t('plugins.ecommerce.messages.my_orders', default: 'My Orders'), url_for(action: :index)]
  end
end
