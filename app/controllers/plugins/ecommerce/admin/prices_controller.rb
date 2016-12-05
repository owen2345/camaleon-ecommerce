class Plugins::Ecommerce::Admin::PricesController < Plugins::Ecommerce::AdminController
  before_action :set_shipping_method

  def index
  end

  def new
    @price = {}
    add_breadcrumb("#{t('plugins.ecommerce.new')}")
    render 'form'
  end

  def show
  end

  def edit
    @price = @prices[params[:id].to_sym] || {}
    add_breadcrumb("#{t('camaleon_cms.admin.button.edit')}")
    render 'form'
  end

  def create
    _id = Time.now.to_i.to_s
    data = params[:price]
    data[:id] = _id
    @prices[_id] = data
    @shipping_method.set_meta('prices', @prices)
    flash[:notice] = t('camaleon_cms.admin.post_type.message.created')
    redirect_to action: :index
  end

  def update
    _id = params[:id]
    @price = @prices[params[:id].to_sym] || {}
    @prices[_id] = @price.merge(params[:price])
    @shipping_method.set_meta('prices', @prices)
    flash[:notice] = t('camaleon_cms.admin.post_type.message.updated')
    redirect_to action: :index
  end

  def destroy
    @prices.delete(params[:id].to_sym)
    @shipping_method.set_meta('prices', @prices)
    flash[:notice] = t('camaleon_cms.admin.post_type.message.deleted')
    redirect_to action: :index
  end



  private
  def set_shipping_method
    @shipping_method = current_site.shipping_methods.find(params[:shipping_method_id])
    add_breadcrumb(t("plugins.ecommerce.shipping_methods"))
    add_breadcrumb(@shipping_method.name)
    add_breadcrumb(t("plugins.ecommerce.shipping_prices"), admin_plugins_ecommerce_shipping_method_prices_path(params[:shipping_method_id]))
    @prices = @shipping_method.get_meta("prices", {})
  end

end
