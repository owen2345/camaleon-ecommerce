=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::Front::OrdersController < Plugins::Ecommerce::FrontController
  before_action :commerce_authenticate
  before_action :set_bread
  def index
    @orders = current_site.orders.set_user(current_user).decorate
    render "index"
  end

  def show
    @order = current_site.orders.find_by_slug(params[:order]).decorate
    @ecommerce_bredcrumb << [t('plugins.ecommerce.messages.detail_order', default: "Detail order: #%{order}", order: params[:order])]
  end



  private
  def set_bread
    @ecommerce_bredcrumb << [t('plugins.ecommerce.messages.my_orders', default: 'My Orders'), url_for(action: :index)]
  end
end
