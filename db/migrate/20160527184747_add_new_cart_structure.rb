class AddNewCartStructure < ActiveRecord::Migration
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
    
    Plugins::Ecommerce::LegacyOrder.reset_column_information
    
    CamaleonCms::Meta.where(object_class: 'Plugins::Ecommerce::Order').
      update_all(object_class: 'Plugins::Ecommerce::LegacyOrder')

    # Plugins::Ecommerce::Order.transaction { Plugins::Ecommerce::Order.destroy_all }

    Plugins::Ecommerce::LegacyOrder.order(:created_at).find_each do |legacy_order|
      details = legacy_order.decorate.details
      order = Plugins::Ecommerce::Order.new(
        name: legacy_order.name,
        description: legacy_order.description,
        slug: legacy_order.slug,
        status: legacy_order.status,
        created_at: legacy_order.created_at,
        updated_at: legacy_order.updated_at,
        received_at: details.received_at,
        accepted_at: details.accepted_at,
        shipped_at: details.shipped_at,
        closed_at: details.closed_at,
        user_id: legacy_order.user_id,
        # not 100% sure on parent_id -> site_id mapping
        site_id: legacy_order.parent_id,
        # not mapped fields because they are always nil in my orders:
        # count, term_group, term_order
      )
      order.save(validate: false)
      
      legacy_order.metas.each do |legacy_meta|
        meta = CamaleonCms::Meta.new(
          object_class: 'Plugins::Ecommerce::Cart',
          objectid: order.id,
          key: legacy_meta.key,
          value: legacy_meta.value,
        )
        meta.save(validate: false)
      end
      
      order.reload
      payment_meta = order.get_meta('payment')
      if payment_meta
        order.set_meta('payment_method_id', payment_meta['payment_id'])
        order.payment_method_id = payment_meta['payment_id']
        order.shipping_method_id = payment_meta['shipping_method']
        order.coupon = payment_meta['coupon_code'],
        order.the_coupon_amount = payment_meta['coupon_amount'],
        order.save(validate: false)
      end
      
      if order.user
        order.user.set_option('phone', details.phone)
      end
      
      order.get_meta('products').each do |key, product|
        order.product_items.create(
          product_id: product['product_id'],
          qty: product['qty'],
          cache_the_price: product['price'],
          cache_the_title: product['product_title'],
          cache_the_tax: product['tax'],
          cache_the_sub_total: product['price'].to_f*product['qty'].to_f,
        )
      end
      
      order.reload
      c = Plugins::Ecommerce::CartDecorator.new(order)
      order.update_columns(
        amount: order.total_amount,
        cache_the_total: c.the_price, 
        cache_the_sub_total: c.the_sub_total,
        cache_the_tax: c.the_tax_total,
        cache_the_weight: c.the_weight_total,
        cache_the_discounts: c.the_total_discounts,
        cache_the_shipping: c.the_total_shipping,
      )
    end

    #drop_table :plugins_order_details
  end
end
