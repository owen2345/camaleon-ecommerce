class MoveFeaturedAttributeOfProducts < ActiveRecord::Migration
  def change
    Cama::Site.all.each do |site|
      ptype = site.post_types.where(slug: 'commerce').first
      if ptype.present?
        ptype.posts.filter_by_field('ecommerce_featured', value: '1').each do |post|
          post.update_column(:is_feature, true)
        end
        field = ptype.get_field_object('ecommerce_featured')
        field.destroy if field.present?
        ptype.set_option('has_featured', true)
      end
    end
  end
end
