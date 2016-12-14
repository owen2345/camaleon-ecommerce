class Plugins::Ecommerce::Admin::SettingsController < Plugins::Ecommerce::AdminController
  add_breadcrumb I18n.t("plugins.ecommerce.e_commerce")
  def index
    @setting = current_site.e_settings
  end

  # save settings
  def saved
    current_site.e_settings(params[:setting])
    flash[:notice] = t('camaleon_cms.admin.post_type.message.updated')
    redirect_to action: :index
  end
end
