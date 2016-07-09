class AddProductAttributesStructure < ActiveRecord::Migration
  def change
    create_table :plugins_ecommerce_attributes do |t|
      t.string :key, :label
      t.integer :parent_id, index: true
      t.integer :site_id, index: true
      t.integer :position, default: 0
    end

    create_table :plugins_ecommerce_product_variations do |t|
      t.decimal :amount, :precision => 8, :scale => 2
      t.belongs_to :product, index: true
      t.string :photo, :sku
      t.integer :weight
      t.integer :position, :qty, default: 0
      t.string :attribute_ids
    end

    add_column :plugins_ecommerce_products, :variation_id, :integer
  end
end
