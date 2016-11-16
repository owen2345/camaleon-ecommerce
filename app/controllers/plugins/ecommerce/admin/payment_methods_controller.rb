class Plugins::Ecommerce::Admin::PaymentMethodsController < Plugins::Ecommerce::AdminController
  before_action :set_order, only: ['show','edit','update','destroy']

  def index
    @payment_methods = current_site.payment_methods.paginate(:page => params[:page], :per_page => current_site.admin_per_page)
  end

  def new
    @payment_method = current_site.payment_methods.new
    @payment_method.status = 1
    add_breadcrumb("#{t('plugin.ecommerce.new')}")
    render 'form'
  end

  def show
    add_breadcrumb("#{t('plugin.ecommerce.table.details')}")
    @payment_method = @payment_method.decorate
  end

  def edit
    add_breadcrumb("#{t('camaleon_cms.admin.button.edit')}")
    render 'form'
  end

  def create
    @payment_method = current_site.payment_methods.new(payment_permit_data)
    if @payment_method.save
      @payment_method.set_meta('_default',params[:options])
      flash[:notice] = t('camaleon_cms.admin.post_type.message.created')
      redirect_to action: :index
    else
      render 'form'
    end
  end

  def update
    if @payment_method.update(payment_permit_data)
      @payment_method.set_meta('_default',params[:options])
      flash[:notice] = t('camaleon_cms.admin.post_type.message.updated')
      redirect_to action: :index
    else
      render 'form'
    end
  end

  private
  def payment_permit_data
    params.require(:plugins_ecommerce_payment_method).permit!
  end

  def set_order
    @payment_method = current_site.payment_methods.find(params[:id])#.decorate
  end
end
