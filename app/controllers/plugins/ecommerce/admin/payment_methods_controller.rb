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

    if defined?(params[:options][:type]) && params[:options][:type] == 'paypal'
      unless valid_paypal_data(params[:options])
        flash.now[:error] = "#{t('plugin.ecommerce.message.error_paypal_values')}"
        render 'form'
        return
      end
    end

    #FIXME create valid_authorize_net_data function

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

  def valid_paypal_data(data)
    ActiveMerchant::Billing::Base.mode = data[:paypal_sandbox].to_s.to_bool ? :test : :production
    paypal_options = {
        :login => data[:paypal_login],
        :password => data[:paypal_password],
        :signature => data[:paypal_signature]
    }
    opts = {
        :ip => request.remote_ip,
        :return_url => plugins_ecommerce_order_success_url(order: 'test'),
        :cancel_return_url => plugins_ecommerce_order_cancel_url(order: 'test')
    }
    @gateway = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
    response = @gateway.setup_authorization(500, opts)
    response.success?
  end
end
