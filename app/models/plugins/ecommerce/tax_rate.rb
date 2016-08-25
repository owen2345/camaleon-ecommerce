class Plugins::Ecommerce::TaxRate < CamaleonCms::TermTaxonomy
  default_scope { where(taxonomy: :ecommerce_tax_rate) }
  belongs_to :site, :class_name => "CamaleonCms::Site", foreign_key: :parent_id
  scope :actives, -> {where(status: '1')}

  def the_name
    "#{name} (#{options[:rate]}%)"
  end

end
