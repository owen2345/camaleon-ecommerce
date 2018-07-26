class AddTitleToProductVariation < ActiveRecord::Migration[5.0]
  def change
    add_column :plugins_ecommerce_product_variations, :title, :string
  end
end
