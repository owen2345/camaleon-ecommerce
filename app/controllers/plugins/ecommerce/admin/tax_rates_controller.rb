class Plugins::Ecommerce::Admin::TaxRatesController < Plugins::Ecommerce::AdminController
  before_action :set_order, only: ['show','edit','update','destroy']

  def index
    @tax_rates = current_site.tax_rates.paginate(:page => params[:page], :per_page => current_site.admin_per_page)
  end

  def new
    @tax_rate = current_site.tax_rates.new
    add_breadcrumb("#{t('plugin.ecommerce.new')}")
    render 'form'
  end

  def show
  end

  def edit
    add_breadcrumb("#{t('camaleon_cms.admin.button.edit')}")
    render 'form'
  end

  def create
    @tax_rate = current_site.tax_rates.new(tax_rate_permit_data)
    if @tax_rate.save
      @tax_rate.set_meta('_default', params[:options])
      flash[:notice] = t('camaleon_cms.admin.post_type.message.created')
      redirect_to action: :index
    else
      render 'form'
    end
  end

  def update
    if @tax_rate.update(tax_rate_permit_data)
      @tax_rate.set_meta('_default', params[:options])
      flash[:notice] = t('camaleon_cms.admin.post_type.message.updated')
      redirect_to action: :index
    else
      render 'form'
    end
  end




  private
  def tax_rate_permit_data
   params.require(:plugins_ecommerce_tax_rate).permit!
  end

  def set_order
    @tax_rate = current_site.tax_rates.find(params[:id])
  end

end
