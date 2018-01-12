class AddProductTypeToProductVariation < CamaManager.migration_class
  def change
    add_column :plugins_ecommerce_product_variations, :product_type, :string, default: 'physical_product'
  end
end
