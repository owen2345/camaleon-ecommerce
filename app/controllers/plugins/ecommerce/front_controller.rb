=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::FrontController < CamaleonCms::Apps::PluginsFrontController
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
      flash[:error] = "Invalid Access"
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
      flash[:notice] = "Account created successfully"
      login_user(@user, false, (cookies[:return_to] || plugins_ecommerce_orders_path))
      return cookies.delete(:return_to)
    else
      flash[:error] = "Errors occurred"
      return register
    end
  end

  private
  def save_cache_redirect
    cookies[:return_to] = params[:return_to] if params[:return_to].present?
  end
end
