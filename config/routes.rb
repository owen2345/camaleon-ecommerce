Rails.application.routes.draw do
  scope '(:locale)', locale: /#{PluginRoutes.all_locales}/, :defaults => {} do
    # frontend
    namespace :plugins do
      namespace 'ecommerce' do
        controller :front do
          get 'login'
          post 'login' => :do_login
          get 'register'
          post 'register' => :do_register
        end

        scope :checkout, as: :checkout do
          controller 'front/checkout' do
            get 'success_paypal'
            get 'cancel_paypal'
            post 'pay_by_bank_transfer'
            post 'pay_by_credit_card'
            post 'pay_by_authorize_net'
            post 'pay_by_stripe'
            post 'pay_by_paypal'
            post 'pay_by_on_delivery'
          end
        end

        get 'checkout' => 'front/checkout#index'
        post 'checkout/step_address' => 'front/checkout#step_address'
        post 'checkout/step_shipping' => 'front/checkout#step_shipping'
        get 'checkout/cart' => 'front/checkout#cart_index'
        get 'checkout/complete_free_order' => 'front/checkout#complete_free_order'
        post 'checkout/cart/add' => 'front/checkout#cart_add'
        post 'checkout/cart/update' => 'front/checkout#cart_update'
        delete 'checkout/cart/remove' => 'front/checkout#cart_remove'
        post 'res_coupon' => 'front/checkout#res_coupon'
        get 'orders' => 'front/orders#index'
        get 'orders/:order/show' => 'front/orders#show', as: :order_show
      end
    end
  end

  #Admin Panel
  scope 'admin', as: 'admin' do
    namespace 'plugins' do
      namespace 'ecommerce' do
        get 'index' => 'admin#index'
        get 'product_attributes' => 'admin#product_attributes'
        post 'product_attributes' => 'admin#save_product_attributes'
        resources :orders, controller: 'admin/orders' do
          get 'mark_accepted'
          get 'resend_email'
          get 'mark_bank_confirmed'
          post 'mark_shipped'
          post 'mark_canceled'
        end
        resources :payment_methods, controller: 'admin/payment_methods'
        resources :shipping_methods, controller: 'admin/shipping_methods' do
          resources :prices, controller: 'admin/prices'
        end
        resources :coupons, controller: 'admin/coupons'
        resources :tax_rates, controller: 'admin/tax_rates'
        get 'settings' => 'admin/settings#index'
        post 'settings/saved' => 'admin/settings#saved'
      end
    end
  end

  # main routes
  #scope 'ecommerce', module: 'plugins/ecommerce/', as: 'ecommerce' do
  #  Here my routes for main routes
  #end
end
