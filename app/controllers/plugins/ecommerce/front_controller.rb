class Plugins::Ecommerce::FrontController < CamaleonCms::Apps::PluginsFrontController
  prepend_before_action :init_flash
  before_action :ecommerce_add_assets_in_front
  before_action :save_cache_redirect, only: [:login, :register]
  def login
    redirect_to new_session_path(:user)
  end

  def cart_rescue
    if current_user
      callback_login(current_user)
      return redirect_to cookies.delete(:e_return_to)
    end
    redirect_to plugins_ecommerce_orders_path
  end

  def do_login
    if login_user_with_password(params[:email], params[:password])
      callback_login(@user)
      login_user(@user, false, (cookies[:e_return_to] || plugins_ecommerce_orders_path))
      return cookies.delete(:e_return_to)
    else
      flash[:cama_ecommerce][:error] = t('plugins.ecommerce.messages.invalid_access', default: 'Invalid access')
      return login
    end
  end

  def register
    params[:kind_form] = 'register-form'
    @user ||= current_site.users.new
    render 'login'
  end

  def do_register
    params[:camaleon_cms_user][:username] = params[:camaleon_cms_user][:email] if params[:camaleon_cms_user].present?
    @user = current_site.users.new(params.require(:camaleon_cms_user).permit(:first_name, :last_name, :username, :email, :password, :password_confirmation))
    if @user.save
      flash[:cama_ecommerce][:notice] = t('plugins.ecommerce.messages.created_account', default: "Account created successfully")
      callback_login(@user)
      login_user(@user, false, (cookies[:e_return_to] || plugins_ecommerce_orders_path))
      return cookies.delete(:e_return_to)
    else
      return register
    end
  end

  private
  def save_cache_redirect
    cookies[:e_return_to] = params[:return_to] if params[:return_to].present?
  end

  def commerce_authenticate
    unless cama_sign_in?
      flash[:cama_ecommerce][:error] = t('camaleon_cms.admin.login.please_login')
      cookies[:e_return_to] = request.referer
      redirect_to plugins_ecommerce_login_path
    end
  end

  def init_flash
    flash[:cama_ecommerce] = {} unless flash[:cama_ecommerce].present?
  end

  # callback after log in
  def callback_login(user)
    if cookies[:e_cart_id].present?
      e_current_cart(cookies[:e_cart_id]).change_user(user)
      cookies.delete(:e_cart_id)
    end
  end
end
