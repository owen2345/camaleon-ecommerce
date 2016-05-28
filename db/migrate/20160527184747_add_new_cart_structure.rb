class AddNewCartStructure < ActiveRecord::Migration
  def change
    create_table :plugins_ecommerce_orders do |t|
      t.string :name, :slug, :kind, :coupon, :the_coupon_amount, :currency_code, :payment_data
      t.string :status, default: 'unpaid'
      t.integer :shipping_method_id, :user_id, :site_id, :payment_method_id, index: true
      t.timestamp :paid_at
      t.decimal :amount, :total, :sub_total, :tax_total, :weight_price, :coupon_amount, :precision => 8, :scale => 2
    end

    create_table :plugins_ecommerce_products do |t|
      t.integer :qty, :product_id, :order_id, index: true
      t.string :the_price, :the_title, :the_tax
    end
  end
end
