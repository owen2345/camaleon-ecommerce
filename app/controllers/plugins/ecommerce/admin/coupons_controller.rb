class Plugins::Ecommerce::Admin::CouponsController < Plugins::Ecommerce::AdminController
  before_action :set_order, only: ['show','edit','update','destroy']

  def index
    @coupons = current_site.coupons.paginate(:page => params[:page], :per_page => current_site.admin_per_page)
  end

  def new
    @coupon = current_site.coupons.new
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
    @coupon = current_site.coupons.new(coupons_permit_data)
    if @coupon.save
      @coupon.set_meta('_default', params[:options])
      flash[:notice] = t('camaleon_cms.admin.post_type.message.created')
      redirect_to action: :index
    else
      render 'form'
    end
  end

  def update
    if @coupon.update(coupons_permit_data)
      @coupon.set_meta('_default', params[:options])
      flash[:notice] = t('camaleon_cms.admin.post_type.message.updated')
      redirect_to action: :index
    else
      render 'form'
    end
  end




  private

  def coupons_permit_data
    params.require(:plugins_ecommerce_coupon).permit!
  end
  def set_order
    @coupon = current_site.coupons.find(params[:id])
  end

end
