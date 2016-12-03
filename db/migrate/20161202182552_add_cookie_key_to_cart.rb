class AddCookieKeyToCart < ActiveRecord::Migration
  def change
    add_column :plugins_ecommerce_orders, :visitor_key, :string
  end
end
