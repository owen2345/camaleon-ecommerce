=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::AdminController < CamaleonCms::Apps::PluginsAdminController
  before_action :verify_ecommerce_permission
  def index
    # here your actions for admin panel
  end

  def product_attributes

  end

  def save_product_attributes
    current_site.product_attributes.where.not(id: params[:attribute].keys).destroy_all
    params[:attribute].each do |key, values|
      if key.include?('new')
        group = current_site.product_attributes.create(label: params[:attribute_names][key][:label])
      else
        group = current_site.product_attributes.find(key)
        group.update(label: params[:attribute_names][key][:label])
      end
      group.values.where.not(id: values.map{|v| v[:id] }).delete_all
      values.each do |val|
        data = {key: val[:key], label: val[:value], position: val[:position]}
        if val[:id].present?
          group.values.find(val[:id]).update(data)
        else
          group.values.create(data)
        end
      end
    end
    flash[:notice] = t('.saved_product_attributes', default: 'Attributes Saved')
    redirect_to action: :product_attributes
  end

  private
  def verify_ecommerce_permission
    authorize! :posts, get_commerce_post_type
    add_breadcrumb I18n.t("plugin.ecommerce.e_commerce", default: 'Ecommerce'), admin_plugins_ecommerce_index_path
  end
end
