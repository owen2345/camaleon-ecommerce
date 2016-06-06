=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
class Plugins::Ecommerce::Coupon < CamaleonCms::TermTaxonomy
  default_scope { where(taxonomy: :ecommerce_coupon) }
  belongs_to :site, :class_name => "CamaleonCms::Site", foreign_key: :parent_id
  scope :actives, -> {where(status: '1')}

  def used_times_exceeded?
    (used_applications + 1) > allowed_applications
  end

  def mark_as_used(user = nil)
    set_option('used_applications', used_applications + 1)
  end

  def used_applications
    get_option('used_applications', 0).to_i
  end

  def allowed_applications
    get_option('allowed_applications', 0).to_i
  end

  def expired?
    d = get_option('expirate_date', '')
    if d.present?
      "#{d} 23:59:59".to_datetime.to_i < Time.current.to_i
    else
      false
    end
  end

  def min_cart_total
    get_option('min_cart_total', '')
  end

  def valid_min_price?(price)
    !min_cart_total.present? || min_cart_total.to_i <= price
  end

  def active?
    status.to_s == '1'
  end

end
