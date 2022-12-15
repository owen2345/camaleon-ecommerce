require 'country_select'
require 'ransack'
require 'wicked_pdf'
require 'activemerchant'
module Ecommerce
  class Engine < ::Rails::Engine
    config.after_initialize do |app|
      require_relative '../../config/custom_models'
    end
  end
end
