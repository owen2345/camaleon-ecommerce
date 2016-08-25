class Plugins::Ecommerce::FrontController < CamaleonCms::Apps::PluginsFrontController
  include Plugins::Ecommerce::EcommercePaymentHelper
  before_action :ecommerce_add_assets_in_front
  before_action :save_cache_redirect, only: [:login, :register]
  def login
    @user ||= current_site.users.new
    render 'login'
  end

  def do_login
    if login_user_with_password(params[:username], params[:password])
      login_user(@user, false, (cookies[:return_to] || plugins_ecommerce_orders_path))
      return cookies.delete(:return_to)
    else
      flash[:error] = t('plugins.ecommerce.messages.invalid_access', default: 'Invalid access')
      return login
    end
  end

  def register
    params[:kind_form] = 'register-form'
    @user ||= current_site.users.new
    render 'login'
  end

  def do_register
    @user = current_site.users.new(params.require(:camaleon_cms_user).permit(:first_name, :last_name, :username, :email, :password, :password_confirmation))
    if @user.save
      flash[:notice] = t('plugins.ecommerce.messages.created_account', default: "Account created successfully")
      login_user(@user, false, (cookies[:return_to] || plugins_ecommerce_orders_path))
      return cookies.delete(:return_to)
    else
      return register
    end
  end

  private
  def save_cache_redirect
    cookies[:return_to] = params[:return_to] if params[:return_to].present?
  end

  def commerce_authenticate
    unless cama_sign_in?
      flash[:error] = t('camaleon_cms.admin.login.please_login')
      cookies[:return_to] = request.referer
      redirect_to plugins_ecommerce_login_path
    end
  end
end
