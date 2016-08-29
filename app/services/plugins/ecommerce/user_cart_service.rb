class Plugins::Ecommerce::UserCartService
  def initialize(site, user)
    @site = site
    @user = user
  end
  
  attr_reader :site, :user
  
  def get_cart
    site.carts.set_user(user).active_cart.first_or_create(name: "Cart by #{user.id}").decorate
  end
end
