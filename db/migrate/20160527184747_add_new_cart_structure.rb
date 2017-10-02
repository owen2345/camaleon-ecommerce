class AddNewCartStructure < CamaManager.migration_class
  def change
    create_table :plugins_ecommerce_orders do |t|
      t.string :name, :slug, :kind, :coupon, :the_coupon_amount
      t.string :currency_code, :payment_data
      t.string :status, default: 'unpaid'
      t.integer :shipping_method_id, :user_id, :site_id, :payment_method_id, index: true
      t.timestamp :paid_at, :received_at, :accepted_at, :shipped_at, :closed_at
      t.string :cache_the_total, :cache_the_sub_total, :cache_the_tax
      t.string :cache_the_weight, :cache_the_discounts, :cache_the_shipping
      t.decimal :amount, :precision => 8, :scale => 2
      t.text :description
      t.timestamps null: false
    end

    create_table :plugins_ecommerce_products do |t|
      t.integer :qty, :product_id, :order_id, index: true
      t.string :cache_the_price, :cache_the_title, :cache_the_tax
      t.string :cache_the_sub_total
    end

    #drop_table :plugins_order_details
  end
end
