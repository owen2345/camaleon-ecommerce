=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::ProductItems < ActiveRecord::Base
  self.table_name = 'plugins_ecommerce_products'
  belongs_to :cart, class_name: 'Plugins::Ecommerce::Cart'
  belongs_to :order, class_name: 'Plugins::Ecommerce::Order'
  belongs_to :product, foreign_key: :product_id, class_name: 'CamaleonCms::Post'

  def the_sub_total
    puts "@@@@@@@@@@@@@@@@@@: #{self.cart.inspect}"
    "#{(self.cart || self.order).site.decorate.current_unit}#{sprintf('%.2f', sub_total)}"
  end

  def sub_total
    product = product.decorate
    (product.price + product.tax) * self.qty
  end
end
