class MigrateOrderData < ActiveRecord::Migration
  def change
    if Plugins::Ecommerce::LegacyOrder.count > 0
      Plugins::Ecommerce::LegacyOrder.reset_column_information
      
      CamaleonCms::Meta.where(object_class: 'Plugins::Ecommerce::Order').
        update_all(object_class: 'Plugins::Ecommerce::LegacyOrder')

      # Plugins::Ecommerce::Order.transaction { Plugins::Ecommerce::Order.destroy_all }

      product_post_type = CamaleonCms::PostType.where(slug: 'commerce').first
      raise 'Product post type must exist' unless product_post_type
      
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
          p = product_post_type.posts.where(id: product['product_id']).first
          p = Plugins::Ecommerce::ProductDecorator.new(p)
          order.product_items.create(
            product_id: product['product_id'],
            qty: product['qty'],
            cache_the_price: p.the_price,
            cache_the_title: p.title,
            cache_the_tax: '$%.2f' % p.the_tax,
            cache_the_sub_total: '$%.2f' % (product['price'].to_f*product['qty'].to_f),
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
    end
  end
end
