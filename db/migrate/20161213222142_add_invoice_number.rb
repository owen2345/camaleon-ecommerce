class AddInvoiceNumber < ActiveRecord::Migration
  def change
    add_column :plugins_ecommerce_orders, :invoice_number, :string, default: ''
    add_column :plugins_ecommerce_orders, :invoice_path, :string, default: ''
  end
end
