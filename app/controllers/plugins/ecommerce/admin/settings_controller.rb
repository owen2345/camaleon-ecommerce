class Plugins::Ecommerce::Admin::SettingsController < Plugins::Ecommerce::AdminController
  add_breadcrumb I18n.t("plugin.ecommerce.e_commerce")
  def index
    @setting = current_site.get_meta("_setting_ecommerce", {})
  end

  def saved
    current_site.set_meta('_setting_ecommerce', params[:setting])
    flash[:notice] = t('camaleon_cms.admin.post_type.message.updated')
    redirect_to action: :index
  end
end
