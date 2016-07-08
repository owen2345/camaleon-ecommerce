=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::ProductItem < ActiveRecord::Base
  include CamaleonCms::Metas
  self.table_name = 'plugins_ecommerce_products'
  belongs_to :cart, class_name: 'Plugins::Ecommerce::Cart', foreign_key: :order_id
  belongs_to :order, class_name: 'Plugins::Ecommerce::Order'
  belongs_to :product, foreign_key: :product_id, class_name: 'CamaleonCms::Post'
  belongs_to :product_variation, class_name: 'Plugins::Ecommerce::ProductVariation'

  def sub_total
    p = self.product.decorate
    (p.price(self.variation_id) + p.tax(self.variation_id)) * self.qty
  end
end
