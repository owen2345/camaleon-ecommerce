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
    authorize! :posts, cama_ecommerce_post_type
    add_breadcrumb I18n.t("plugin.ecommerce.e_commerce", default: 'Ecommerce'), admin_plugins_ecommerce_index_path
  end
end
