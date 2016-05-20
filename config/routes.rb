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

        get 'checkout' => 'front/checkout#index'
        post 'checkout/processing' => 'front/checkout#processing'
        get 'checkout/cart' => 'front/checkout#cart_index'
        post 'checkout/cart/add' => 'front/checkout#cart_add'
        post 'checkout/cart/update' => 'front/checkout#cart_update'
        get 'checkout/cart/remove' => 'front/checkout#cart_remove'
        post 'res_coupon' => 'front/orders#res_coupon'
        get 'orders' => 'front/orders#index'
        get 'orders/:order/show' => 'front/orders#show', as: :order_show
        get 'orders/:order/select_payment' => 'front/orders#select_payment', as: :order_select_payment
        post 'orders/:order/select_payment' => 'front/orders#set_select_payment', as: :order_set_select_payment
        get 'orders/:order/pay' => 'front/orders#pay', as: :order_pay
        get 'orders/:order/success' => 'front/orders#success', as: :order_success
        get 'orders/:order/cancel' => 'front/orders#cancel', as: :order_cancel
        post 'orders/:order/pay_by_bank_transfer' => 'front/orders#pay_by_bank_transfer', as: :order_pay_by_bank_transfer
        post 'orders/:order/pay_by_credit_card' => 'front/orders#pay_by_credit_card', as: :order_pay_by_credit_card
        post 'orders/:order/pay_by_credit_card_authorize_net' => 'front/orders#pay_by_credit_card_authorize_net', as: :order_pay_by_credit_card_authorize_net
        post 'orders/:order/pay_by_authorize_net' => 'front/orders#pay_by_authorize_net', as: :order_pay_by_authorize_net
      end
    end
  end

  #Admin Panel
  scope 'admin', as: 'admin' do
    namespace 'plugins' do
      namespace 'ecommerce' do
        get 'index' => 'admin#index'
        resources :orders, controller: 'admin/orders' do
          post 'accepted'
          post 'shipped'
          get 'canceled'
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
