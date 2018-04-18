module Plugins::Ecommerce::EcommerceHelper
  include Plugins::Ecommerce::EcommerceEmailHelper
  def ecommerce_admin_product_form(args)
    if args[:post_type].slug == 'commerce'
      append_asset_libraries({ecommerce: {css: [], js: [plugin_asset_path('admin_product')]}})
      args[:html] << render(partial: plugin_view('admin/products/variations'), locals:{post_type: args[:post_type], product: args[:post] })
    end
  end

  # return ecommerce posttype
  def cama_ecommerce_post_type
    @_cache_ecommerce_post_type ||= current_site.post_types.where(slug: 'commerce').first.try(:decorate)
  end

  def ecommerce_front_before_load
    e_current_visitor_currency(params[:cama_change_currency]) if params[:cama_change_currency].present?
    @ecommerce_breadcrumb = [].push([t('plugins.ecommerce.front.breadcrumb.home', default: 'Home'), cama_root_url])
  end

  def ecommerce_admin_before_load
    # add menu bar
    pt = current_site.post_types.hidden_menu.where(slug: "commerce").first
    if pt.present?
      items_i = []
      items_i << {icon: "list", title: t('plugins.ecommerce.all_products'), url: cama_admin_post_type_posts_path(pt.id)} if can? :posts, pt
      items_i << {icon: "plus", title: t('camaleon_cms.admin.post_type.add_new', default: 'Add new'), url: new_cama_admin_post_type_post_path(pt.id)} if can? :create_post, pt
      if pt.manage_categories?
        items_i << {icon: "folder-open", title: t('camaleon_cms.admin.post_type.categories', default: 'Categories'), url: cama_admin_post_type_categories_path(pt.id)} if can? :categories, pt
      end
      if pt.manage_tags?
        items_i << {icon: "tags", title: t('camaleon_cms.admin.post_type.tags', default: 'Tags'), url: cama_admin_post_type_post_tags_path(pt.id)} if can? :post_tags, pt
      end
      if can? :posts, pt
        items_i << {icon: "reorder", title: "<span>#{t('plugins.ecommerce.orders', default: 'Orders')} <small class='label label-primary'>#{current_site.orders.size}</small></span>", url: admin_plugins_ecommerce_orders_path}
        items_i << {icon: "money", title: t('plugins.ecommerce.tax_rates', default: 'Tax rates'), url: admin_plugins_ecommerce_tax_rates_path}
        items_i << {icon: "taxi", title: t('plugins.ecommerce.shipping_methods', default: 'Shipping Methods'), url: admin_plugins_ecommerce_shipping_methods_path}
        items_i << {icon: "credit-card", title: t('plugins.ecommerce.payment_methods', default: 'Payment Methods'), url: admin_plugins_ecommerce_payment_methods_path}
        items_i << {icon: "tag", title: t('plugins.ecommerce.coupons', default: 'Coupons'), url: admin_plugins_ecommerce_coupons_path}
        items_i << {icon: "cubes", title: t('plugins.ecommerce.product_attributes', default: 'Product Attributes'), url: admin_plugins_ecommerce_product_attributes_path}
        items_i << {icon: "cogs", title: t('camaleon_cms.admin.button.settings', default: 'Settings'), url: admin_plugins_ecommerce_settings_path}
        hooks_run('plugin_ecommerce_after_menus', items_i) # permit to add menus for ecommerce plugin
      end

      admin_menu_insert_menu_after("content", "e-commerce", {icon: "shopping-cart", title: t('plugins.ecommerce.e_commerce', default: 'E-commerce'), url: "", items: items_i}) if items_i.present?
    end
  end

  def ecommerce_app_before_load
  end

  # permit to generate invoice PDF by background just before delivery email
  def ecommerce_admin_before_email_send(args)
    if args[:ecommerce_invoice].present?
      File.open(args[:ecommerce_invoice][:pdf_path], 'wb'){|file| file << WickedPdf.new.pdf_from_string(args[:ecommerce_invoice][:html], encoding: 'utf8') }
    end
  end

  # here all actions on plugin destroying
  # plugin: plugin model
  def ecommerce_on_destroy(plugin)
  end

  # here all actions on going to active
  # you can run sql commands like this:
  # results = ActiveRecord::Base.connection.execute(query);
  # plugin: plugin model
  def ecommerce_on_active(plugin)
    generate_custom_field_products
  end

  # here all actions on going to inactive
  # plugin: plugin model
  def ecommerce_on_inactive(plugin)
    current_site.post_types.hidden_menu.where(slug: "commerce").first.destroy
  end

  # callback after create/update products
  def ecommerce_admin_product_saved(args)
    if args[:post_type].slug == 'commerce'
      params[:product_variation] ||= {}

      # verify no deletable variances
      no_deletable_variances = false
      args[:post].product_variations.where.not(id: params[:product_variation].keys).each{|prod| no_deletable_variances = true unless prod.destroy }
      flash[:warning] += t('plugins.ecommerce.variations.not_deletable_product_variations', default: 'Some Product variations can not be deleted.') if no_deletable_variances

      params[:product_variation].each do |p_key, p_var|
        data = {amount: p_var[:price], photo: p_var[:photo], title: p_var[:title], sku: p_var[:sku], weight: p_var[:weight], qty: p_var[:qty], attribute_ids: (p_var[:attributes] || []).map{|at| at[:value] }.join(','), product_type: p_var[:product_type]}
        if p_key.include?('new_') # new variation
          args[:post].product_variations.create(data)
        else
          args[:post].product_variations.find(p_key).update(data)
        end
      end
    end
  end

  def ecommerce_add_assets_in_front
    append_asset_libraries({ecommerce_front: {css: [plugin_gem_asset('front')], js: [plugin_gem_asset('cart')]}})
  end

  private
  def generate_custom_field_products
    ecommerce = current_site.post_types.hidden_menu.where(slug: "commerce").first
    unless ecommerce.present?
      ecommerce = current_site.post_types.hidden_menu.new(slug: "commerce", name: "Product")
      if ecommerce.save
        ecommerce.set_options({
                                 has_category: true,
                                 has_tags: true,
                                 not_deleted: true,
                                 has_summary: true,
                                 has_content: true,
                                 has_comments: true,
                                 has_picture: true,
                                 has_template: false,
                                 has_featured: true,
                                 cama_post_decorator_class: 'Plugins::Ecommerce::ProductDecorator'
                               })
        ecommerce.categories.create({name: 'Uncategorized', slug: 'Uncategorized'.parameterize})
      end
      ecommerce.set_options({posts_feature_image_label: 'plugins.ecommerce.product.image_label',
                              posts_feature_image_label_default: 'Product Image'})
    end

    unless ecommerce.get_field_groups.where(slug: "plugin_ecommerce_product_data").present?
      ecommerce.get_field_groups.destroy_all
      group = ecommerce.add_custom_field_group({name: 'Products Details', slug: 'plugin_ecommerce_product_data'})
      group.add_manual_field({"name" => "t('plugins.ecommerce.product.product_type', default: 'Product Type')", "slug" => "ecommerce_product_type"}, {field_key: "select", required: true, multiple_options:[{title:'Physical Product', value:'physical_product',default: 1},{title:'Service Product', value:'service_product'}] , label_eval: true})

      group.add_manual_field({"name" => "t('plugins.ecommerce.product.sku', default: 'Sku')", "slug" => "ecommerce_sku"}, {field_key: "text_box", required: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugins.ecommerce.product.attrs', default: 'Attributes')", "slug" => "ecommerce_attrs", description: "t('plugins.ecommerce.product.attrs_descr', default: 'Please enter your product attributes separated by commas, like: Color ==> Red, Blue, Green')"}, {field_key: "field_attrs", required: false, multiple: true, false: true, translate: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugins.ecommerce.product.photos', default: 'Photos')", "slug" => "ecommerce_photos"}, {field_key: "image", required: false, multiple: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugins.ecommerce.product.price', default: 'Price')", "slug" => "ecommerce_price", "description" => "t('plugins.ecommerce.product.current_unit', default: 'Current unit: %{unit}', unit: current_site.current_unit.to_s)"}, {field_key: "numeric", required: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugins.ecommerce.product.tax', default: 'Tax')", "slug" => "ecommerce_tax"}, {field_key: "select_eval", required: false, command: "options_from_collection_for_select(current_site.tax_rates.all, \"id\", \"the_name\")", label_eval: true})
      group.add_manual_field({"name" => "t('plugins.ecommerce.product.weight', default: 'Weight')", "slug" => "ecommerce_weight", "description" => "t('plugins.ecommerce.product.current_weight', default: 'Current weight: %{weight}', weight: current_site.current_weight.to_s)"}, {field_key: "text_box", required: true, label_eval: true})
      # changed to validate using the quantity of the inventory
      # group.add_manual_field({"name" => "t('plugins.ecommerce.product.stock', default: 'Stock')", "slug" => "ecommerce_stock"}, {field_key: "checkbox", default: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugins.ecommerce.product.qty', default: 'Quantity')", "slug" => "ecommerce_qty"}, {field_key: "numeric", required: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugins.ecommerce.product.files', default: 'Product files')", "slug" => "ecommerce_files"}, {field_key: "private_file", multiple: true, required: false, label_eval: true})
    end
  end
end