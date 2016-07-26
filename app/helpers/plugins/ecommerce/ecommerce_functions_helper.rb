=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
#encoding: utf-8
module Plugins::Ecommerce::EcommerceFunctionsHelper
  def self.included(klass)
    klass.helper_method [:e_get_currency_units, :e_get_currency_weight, :e_symbol_by_code, :ecommerce_custom_payment_methods] rescue ""
  end
  def e_get_currency_weight
    r = {}
    JSON.parse('[{"code":"kg","name":'+"#{t('plugin.ecommerce.select.kilogram').to_json}"'},{"code":"lb","name":'+"#{t('plugin.ecommerce.select.pound').to_json}"'},{"code":"dr","name":'+"#{t('plugin.ecommerce.select.dram').to_json}"'},{"code":"gr","name":'+"#{t('plugin.ecommerce.select.grain').to_json}"'},{"code":"g","name":'+"#{t('plugin.ecommerce.select.gram').to_json}"'},{"code":"UK","name":'+"#{t('plugin.ecommerce.select.hundredweight').to_json}"'},{"code":"mg","name":'+"#{t('plugin.ecommerce.select.milligram').to_json}"'},{"code":"oz","name":'+"#{t('plugin.ecommerce.select.ounce').to_json}"'},{"code":"t","name":'+"#{t('plugin.ecommerce.select.tonne').to_json}"'}]').collect do |item|
      item['name'] = item['name'].to_s.titleize
      r[item['code']] = item
    end
    @e_get_currency_weight ||= r
  end

  def e_get_currency_units
    @e_get_currency_units ||= lambda{
      file = File.read("#{File.dirname(__FILE__)}/../../../../config/currency.json")
      args = {currencies: JSON.parse(file)}; hooks_run("ecommerce_currencies", args)
      args[:currencies]
    }.call
  end

  def e_symbol_by_code(unit)
    e_get_currency_units[unit]['symbol'] rescue '$xx'
  end

  # use in add cart
  def e_add_data_product(data, product_id)
    post = CamaleonCms::Post.find(product_id).decorate
    attributes = post.attributes
    attributes[:content] = ''
    data[:product_title] = post.the_title
    data[:price] = post.get_field_value(:ecommerce_price)
    data[:weight] = post.get_field_value(:ecommerce_weight)
    data[:tax_rate_id] = post.get_field_value(:ecommerce_tax)
    tax_product = current_site.tax_rates.find(data[:tax_rate_id]).options[:rate].to_f  rescue 0
    data[:tax_percent] = tax_product
    data[:tax] = data[:price].to_f * data[:tax_percent] / 100 rescue 0
    data[:currency_code] = current_site.currency_code
    metas = {}
    post.metas.map{|m| metas[m.key] = m.value }
    data.merge(post: attributes, fields: post.get_field_values_hash, meta: metas)
  end

  def ecommerce_custom_payment_methods
    @_ecommerce_custom_payment_methods ||= lambda{
      args = {custom_payment_methods: {}}; hooks_run("ecommerce_custom_payment_methods", args)
      # Sample:
      # args[:custom_payment_methods][:pay_u] = {
        # title: 'Pay U',
        # settings_view_path: '/my_plugin/views/payu/settings', # view must be like this: <div class="form-group"> <label>Key</label><br> <%= text_field_tag('options[payu_key]', options[:payu_key], class: 'form-control required') %> </div>
        # payment_form_view_path: '/my_plugin/views/payu/payment_form',
          # # view must include the payment form with your custom routes to process the payment,
          # # sample: https://github.com/owen2345/camaleon-ecommerce/blob/master/app/controllers/plugins/ecommerce/front/checkout_controller.rb#L120
          # #         https://github.com/owen2345/camaleon-ecommerce/blob/master/app/views/plugins/ecommerce/partials/checkout/_payments.html.erb#L104
      # }
    }.call
    args[:custom_payment_methods]
  end

end
