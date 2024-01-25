$(function() {
  const form = $('#form-post');
  let variation_id = 1;
  const product_variations = form.find('#product_variations');
  form.find('.content-frame-body > .c-field-group:last').after(product_variations.removeClass('hidden'));

  // photo uploader
  product_variations.on('click', '.product_variation_photo_link', function() {
    const $input = $(this).prev();
    $.fn.upload_filemanager({
      formats: "image",
      dimension: $input.attr("data-dimension") || '',
      versions: $input.attr("data-versions") || '',
      thumb_size: $input.attr("data-thumb_size") || '',
      selected: (file, response) => { $input.val(file.url) }
    });
    return false;
  });

  const cache_variation = product_variations.find('.blank_product_variation').remove().clone().removeClass('hidden');
  const cache_values = cache_variation.find('.sortable_values > li:first').remove().clone();

  // add new variation
  product_variations.find('.add_new_variation').click(function() {
    const clone = cache_variation.clone().attr('data-id', 'new_'+(variation_id+=1));
    product_variations.children('.variations_sortable').append(clone);
    clone.trigger('fill_variation_id');
    check_variation_status();
    return false;
  });

  // add new variation value
  product_variations.on('click', '.add_new_value', function() {
    const clone = cache_values.clone();
    const key = $(this).closest('.product_variation').attr('data-id');
    clone.find('input, select').each(function() {
      $(this).attr('name', $(this).attr('name').replace('[]', '['+key+']')).removeAttr('id');
    });
    $(this).closest('.variation_attributes').find('.sortable_values').append(clone);
    clone.find('.product_attribute_select').trigger('change');
    return false;
  });

  // change attribute
  product_variations.on('change', '.product_attribute_select', function() {
    const v = $(this).val();
    const sel = $(this).closest('.row').find('.product_attribute_vals_select').html('');
    for (let attr of PRODUCT_ATTRIBUTES) {
      if (attr.id == v) {
        sel.append('<option value="'+value.id+'">'+value.label.replace(/</g, '&lt;')+'</option>');
      }
    }
  });

  product_variations.on('fill_variation_id', '.product_variation', function() {
    const key = $(this).attr('data-id');
    $(this).find('input, select').each(function() {
      $(this).attr('name', $(this).attr('name').replace('[]', '['+key+']')).removeAttr('id');
    });
    $(this).find('.sortable_values').sortable({handle: '.val_sorter'});
  });

  // sortables
  product_variations.find('.sortable_values').sortable({handle: '.val_sorter'});
  product_variations.find('.variations_sortable').sortable({handle: '.variation_sorter', update(){
    $(this).children().each(function(index){
      $(this).find('.product_variation_position').val(index);
    });
  }
  });

  // delete actions
  product_variations.on('click', '.val_del', function() {
    $(this).closest('li').fadeOut('slow', function() {
      $(this).remove();
    });
    return false;
  });
  product_variations.on('click', '.var_del', function() {
    if (!confirm(product_variations.attr('data-confirm-msg'))) {
      return false;
    }
    $(this).closest('.product_variation').fadeOut('slow', function() {
      $(this).remove();
      check_variation_status();
    });
    return false;
  });

  // check the variation status and disable or enable some custom fields
  const check_variation_status = function() {
    const fields = [
        'ecommerce_sku', 'ecommerce_price', 'ecommerce_weight', 'ecommerce_stock', 'ecommerce_qty', 'ecommerce_photos'
    ];
    if (product_variations.find('.product_variation').length > 0) { // is a variation product
      for (let key of fields) {
        let p_field = form.find('.c-field-group .item-custom-field[data-field-key="'+key+'"]');
        p_field.hide().find('.required').addClass('e_skip_required').removeClass('required');
      }
    } else {
      for (let key of fields) {
        let p_field = form.find('.c-field-group .item-custom-field[data-field-key="'+key+'"]');
        p_field.show().find('.e_skip_required').removeClass('e_skip_required').addClass('required');
      }
    }
  };

  check_variation_status();
});
