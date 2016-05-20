=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
module Plugins::Ecommerce::EcommerceHelper
  include Plugins::Ecommerce::EcommerceEmailHelper

  def ecommerce_on_render_post(d)

  end

  def ecommerce_on_render_post_type(d)

  end

  def ecommerce_admin_list_post(d)

  end

  def ecommerce_form_post(d)
    if d[:post_type].slug == 'commerce'
      append_asset_libraries({ecommerce: {css: [], js: [plugin_gem_asset('fix_form')]}})
    end
    d
  end

  def ecommerce_front_before_load
    @ecommerce_post_type = current_site.post_types.where(slug: 'commerce').first.decorate
    @ecommerce_bredcrumb = [].push(["Home", cama_root_url])
  end

  def ecommerce_admin_before_load
    # add menu bar
    pt = current_site.post_types.hidden_menu.where(slug: "commerce").first
    if pt.present?
      items_i = []
      items_i << {icon: "list", title: t('plugin.ecommerce.all_products'), url: cama_admin_post_type_posts_path(pt.id)} if can? :posts, pt
      items_i << {icon: "plus", title: t('camaleon_cms.admin.post_type.add_new', default: 'Add new'), url: new_cama_admin_post_type_post_path(pt.id)} if can? :create_post, pt
      if pt.manage_categories?
        items_i << {icon: "folder-open", title: t('camaleon_cms.admin.post_type.categories', default: 'Categories'), url: cama_admin_post_type_categories_path(pt.id)} if can? :categories, pt
      end
      if pt.manage_tags?
        items_i << {icon: "tags", title: t('camaleon_cms.admin.post_type.tags', default: 'Tags'), url: cama_admin_post_type_post_tags_path(pt.id)} if can? :post_tags, pt
      end
      if can? :posts, pt
        items_i << {icon: "reorder", title: "<span>#{t('plugin.ecommerce.orders', default: 'Orders')} <small class='label label-primary'>#{current_site.orders.size}</small></span>", url: admin_plugins_ecommerce_orders_path}
        items_i << {icon: "money", title: t('plugin.ecommerce.tax_rates', default: 'Tax rates'), url: admin_plugins_ecommerce_tax_rates_path}
        items_i << {icon: "taxi", title: t('plugin.ecommerce.shipping_methods', default: 'Shipping Methods'), url: admin_plugins_ecommerce_shipping_methods_path}
        items_i << {icon: "credit-card", title: t('plugin.ecommerce.payment_methods', default: 'Payment Methods'), url: admin_plugins_ecommerce_payment_methods_path}
        items_i << {icon: "tag", title: t('plugin.ecommerce.coupons', default: 'Coupons'), url: admin_plugins_ecommerce_coupons_path}
        items_i << {icon: "cogs", title: t('camaleon_cms.admin.button.settings', default: 'Settings'), url: admin_plugins_ecommerce_settings_path}
      end

      admin_menu_insert_menu_after("content", "e-commerce", {icon: "shopping-cart", title: t('plugin.ecommerce.e_commerce', default: 'E-commerce'), url: "", items: items_i}) if items_i.present?
    end

    # add assets admin
    append_asset_libraries({ecommerce: {css: [plugin_gem_asset('admin')], js: [plugin_gem_asset('admin')]}})

  end

  def ecommerce_app_before_load

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

  def get_commerce_post_type
    @ecommerce = current_site.post_types.hidden_menu.where(slug: "commerce").first
    unless @ecommerce.present?
      @ecommerce = current_site.post_types.hidden_menu.new(slug: "commerce", name: "Product")
      if @ecommerce.save
        @ecommerce.set_options({
          has_category: true,
          has_tags: true,
          not_deleted: true,
          has_summary: true,
          has_content: true,
          has_comments: true,
          has_picture: true,
          has_template: false,
          has_featured: true,
          cama_post_decorator_class: 'Ecommerce::ProductDecorator'
        })
        @ecommerce.categories.create({name: 'Uncategorized', slug: 'Uncategorized'.parameterize})
      end
      @ecommerce.set_options({posts_feature_image_label: 'plugin.ecommerce.product.image_label',
                              posts_feature_image_label_default: 'Product Image'})
    end
  end

  def ecommerce_add_assets_in_front
    append_asset_libraries({ecommerce_front: {css: [plugin_gem_asset('front')], js: [plugin_gem_asset('cart')]}})
  end

  def mark_order_like_received(order)
    order.update({status: 'received'})
    order.details.update({received_at: Time.now})
    send_order_received_email(order)
    # Send email to admins
    send_order_received_admin_notice(order)
  end

  private
  def generate_custom_field_products
    get_commerce_post_type
    unless @ecommerce.get_field_groups.where(slug: "plugin_ecommerce_product_data").present?
      @ecommerce.get_field_groups.destroy_all
      group = @ecommerce.add_custom_field_group({name: 'Products Details', slug: 'plugin_ecommerce_product_data'})
      group.add_manual_field({"name" => "t('plugin.ecommerce.product.sku', default: 'Sku')", "slug" => "ecommerce_sku"}, {field_key: "text_box", required: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugin.ecommerce.product.attrs', default: 'Attributes')", "slug" => "ecommerce_attrs", description: "t('plugin.ecommerce.product.attrs_descr', default: 'Please enter your product attributes separated by commas, like: Color ==> Red, Blue, Green')"}, {field_key: "field_attrs", required: false, multiple: true, false: true, translate: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugin.ecommerce.product.photos', default: 'Photos')", "slug" => "ecommerce_photos"}, {field_key: "image", required: false, multiple: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugin.ecommerce.product.price', default: 'Price')", "slug" => "ecommerce_price", "description" => "t('plugin.ecommerce.product.current_unit', default: 'Current unit: %{unit}', unit: current_site.current_unit.to_s)"}, {field_key: "numeric", required: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugin.ecommerce.product.tax', default: 'Tax')", "slug" => "ecommerce_tax"}, {field_key: "select_eval", required: false, command: "options_from_collection_for_select(current_site.tax_rates.all, \"id\", \"the_name\")", label_eval: true})
      group.add_manual_field({"name" => "t('plugin.ecommerce.product.weight', default: 'Weight')", "slug" => "ecommerce_weight", "description" => "t('plugin.ecommerce.product.current_weight', default: 'Current weight: %{weight}', weight: current_site.current_weight.to_s)"}, {field_key: "text_box", required: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugin.ecommerce.product.stock', default: 'Stock')", "slug" => "ecommerce_stock"}, {field_key: "checkbox", default: true, label_eval: true})
      group.add_manual_field({"name" => "t('plugin.ecommerce.product.qty', default: 'Quantity')", "slug" => "ecommerce_qty"}, {field_key: "numeric", required: true, label_eval: true})
      # group.add_manual_field({"name" => "t('plugin.ecommerce.product.featured', default: 'Is Featured?')", "slug" => "ecommerce_featured"}, {field_key: "checkbox", default: true, label_eval: true})
    end
  end

end
