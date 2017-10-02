class AddCookieKeyToCart < CamaManager.migration_class
  def change
    add_column :plugins_ecommerce_orders, :visitor_key, :string
  end
end
