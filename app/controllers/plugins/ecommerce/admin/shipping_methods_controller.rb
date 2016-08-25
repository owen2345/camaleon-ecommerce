class Plugins::Ecommerce::Admin::ShippingMethodsController < Plugins::Ecommerce::AdminController
  before_action :set_order, only: ['show','edit','update','destroy']

  def index
    @shipping_methods = current_site.shipping_methods.paginate(:page => params[:page], :per_page => current_site.admin_per_page)
  end

  def new
    @shipping_method = current_site.shipping_methods.new
    add_breadcrumb("#{t('plugin.ecommerce.new')}")
    render 'form'
  end

  def show
    add_breadcrumb("#{t('plugin.ecommerce.table.details')}")
  end

  def edit
    add_breadcrumb("#{t('camaleon_cms.admin.button.edit')}")
    render 'form'
  end

  def create
    @shipping_method = current_site.shipping_methods.new(shipping_permit_data)
    if @shipping_method.save
      @shipping_method.set_meta('_default',params[:options])
      flash[:notice] = t('camaleon_cms.admin.post_type.message.created')
      redirect_to action: :index
    else
      render 'form'
    end
  end

  def update
    if @shipping_method.update(shipping_permit_data)
      @shipping_method.set_meta('_default',params[:options])
      flash[:notice] = t('camaleon_cms.admin.post_type.message.updated')
      redirect_to action: :index
    else
      render 'form'
    end
  end


  private
  def set_order
    @shipping_method = current_site.shipping_methods.find(params[:id])
  end

  def shipping_permit_data
    params.require(:plugins_ecommerce_shipping_method).permit!
  end

end
