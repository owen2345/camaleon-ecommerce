$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'ecommerce/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = 'camaleon_ecommerce'
  s.version = Ecommerce::VERSION
  s.authors = ['Owen']
  s.email = ['owenperedo@gmail.com']
  s.homepage = 'http://camaleon.tuzitio.com/store/plugins/6'
  s.summary = ': Summary of Ecommerce.'
  s.description = ': Description of Ecommerce.'
  s.license = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails' #, '~> 4.2', '>= 4.2.4'
  s.add_dependency 'country_select', '~> 2.4'
  s.add_dependency 'activemerchant', '~> 1.54'
  s.add_dependency 'stripe'

  s.add_development_dependency 'sqlite3', '~> 1.3'
end
