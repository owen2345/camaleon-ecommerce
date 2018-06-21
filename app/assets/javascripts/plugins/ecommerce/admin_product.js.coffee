$ ->
  form = $('#form-post')
  variation_id = 1
  product_variations = form.find('#product_variations')
  form.find('.content-frame-body > .c-field-group:last').after(product_variations.removeClass('hidden'))
  SERVICE_PRODUCT_TYPE = "service_product"

  # this variables is defined in _variations.html.erb
  product_type = ORIGIN_PRODUCT_TYPE
  # photo uploader
  product_variations.on('click', '.product_variation_photo_link', ->
    $input = $(this).prev()
    $.fn.upload_filemanager({
      formats: "image",
      dimension: $input.attr("data-dimension") || '',
      versions: $input.attr("data-versions") || '',
      thumb_size: $input.attr("data-thumb_size") || '',
      selected: (file, response) ->
        $input.val(file.url);
    })
    return false
  )

  cache_variation = product_variations.find('.blank_product_variation').remove().clone().removeClass('hidden')
  cache_values = cache_variation.find('.sortable_values > li:first').remove().clone()

  # change product_type
  form.on('change', '.c-field-group .item-custom-field[data-field-key="ecommerce_product_type"] select', ->
    product_type = $(this).val()

    check_product_type()
  )
  # Add min value and step options to hours field
  form.find('.c-field-group .item-custom-field[data-field-key="ecommerce_hours"] input[type="number"]').attr({'min': 0, 'step': 0.5})

  # add new variation
  product_variations.find('.add_new_variation').click ->
    clone = cache_variation.clone().attr('data-id', 'new_'+variation_id+=1)
    product_variations.children('.variations_sortable').append(clone)
    clone.trigger('fill_variation_id')

    if product_type == SERVICE_PRODUCT_TYPE
      fields_not_required = clone.find('.fn-not-service-product-required')
      clone.find('.fn-product-variation-field').attr('value', SERVICE_PRODUCT_TYPE)
      for p_field in  fields_not_required
        $(p_field).hide().find('.required').addClass('e_skip_required').removeClass('required')
    else
      fields_not_required = clone.find('.fn-not-physical-product-required')
      for p_field in  fields_not_required
        $(p_field).hide().find('.required').addClass('e_skip_required').removeClass('required')

    check_variation_status()
    return false

  # add new variation value
  product_variations.on('click', '.add_new_value', ->
    clone = cache_values.clone()
    key = $(this).closest('.product_variation').attr('data-id')
    clone.find('input, select').each(->
      $(this).attr('name', $(this).attr('name').replace('[]', '['+key+']')).removeAttr('id')
    )
    $(this).closest('.variation_attributes').find('.sortable_values').append(clone)
    clone.find('.product_attribute_select').trigger('change')
    return false
  )

  # change attribute
  product_variations.on('change', '.product_attribute_select', ->
    v = $(this).val()
    sel = $(this).closest('.row').find('.product_attribute_vals_select').html('')
    for attr in PRODUCT_ATTRIBUTES
      if `attr.id == v`
        for value in attr.translated_values
          sel.append('<option value="'+value.id+'">'+value.label.replace(/</g, '&lt;')+'</option>')
  )

  product_variations.on('fill_variation_id', '.product_variation', ->
    key = $(this).attr('data-id')
    $(this).find('input, select').each(->
      $(this).attr('name', $(this).attr('name').replace('[]', '['+key+']')).removeAttr('id')
    )
    $(this).find('.sortable_values').sortable({handle: '.val_sorter'})
  )

  # sortables
  product_variations.find('.sortable_values').sortable({handle: '.val_sorter'})
  product_variations.find('.variations_sortable').sortable({handle: '.variation_sorter', update: ()->
    $(this).children().each((index)->
      $(this).find('.product_variation_position').val(index);
    )
  })

  # delete actions
  product_variations.on('click', '.val_del', ->
    $(this).closest('li').fadeOut('slow', ->
      $(this).remove()
    )
    return false
  )
  product_variations.on('click', '.var_del', ->
    unless confirm(product_variations.attr('data-confirm-msg'))
      return false
    $(this).closest('.product_variation').fadeOut('slow', ->
      $(this).remove()
      check_variation_status()
    )
    return false
  )

  set_variantion_physical_product_fields = (p_variation, hide_fields) ->
    fields_not_required = $(p_variation)
      .find('.fn-not-service-product-required')

    set_variantion_fields(fields_not_required, hide_fields)

    $(p_variation)
      .find('.fn-product-variation-field')
      .attr('value', product_type)

  set_variantion_service_product_fields = (p_variation, hide_fields) ->
    fields_not_required = $(p_variation)
      .find('.fn-not-physical-product-required')
    set_variantion_fields(fields_not_required, !hide_fields)


  set_variantion_fields = (fields_not_required, hide_fields) ->
    for p_field in fields_not_required
      if hide_fields
        $(p_field)
          .hide()
          .find('.required')
          .addClass('e_skip_required')
          .removeClass('required')
      else
        $(p_field)
          .show()
          .find('.e_skip_required')
          .removeClass('e_skip_required')
          .addClass('required')

  set_physical_product_fields = (hide_fields) ->
    set_fields(['ecommerce_weight', 'ecommerce_qty'], hide_fields)

  set_service_product_fields = (hide_fields) ->
    set_fields(['ecommerce_bucket', 'ecommerce_hours'], !hide_fields)


  set_fields = (not_physical_product_field_keys, hide_fields) ->
    for field_key in not_physical_product_field_keys
      p_field = form
        .find(
          '.c-field-group .item-custom-field[data-field-key="' + field_key + '"]'
        )

      if hide_fields
       p_field
          .hide()
          .find('.required')
          .addClass('e_skip_required')
          .removeClass('required')
      else
        p_field
          .show()
          .find('.e_skip_required')
          .removeClass('e_skip_required')
          .addClass('required')

  check_product_type  = ->
    if product_variations.find('.product_variation').length > 0
      for p_variation in product_variations.find('.product_variation')
        set_variantion_physical_product_fields(
          p_variation, product_type == SERVICE_PRODUCT_TYPE
        )
        set_variantion_service_product_fields(
          p_variation, product_type == SERVICE_PRODUCT_TYPE
        )
    else
      set_physical_product_fields(product_type == SERVICE_PRODUCT_TYPE)
      set_service_product_fields(product_type == SERVICE_PRODUCT_TYPE)


  check_product_type()

  # check the variation status and disable or enable some custom fields
  check_variation_status = ->
    fields = ['ecommerce_sku', 'ecommerce_price','ecommerce_stock', 'ecommerce_photos', 'ecommerce_bucket', 'ecommerce_hours']

    if product_variations.find('.product_variation').length > 0
      fields.push('ecommerce_weight', 'ecommerce_qty')
      for key in fields
        p_field = form.find('.c-field-group .item-custom-field[data-field-key="'+key+'"]')
        p_field.hide()
               .find('.required')
               .addClass('e_skip_required')
               .removeClass('required')
    else
      if product_type != SERVICE_PRODUCT_TYPE
        fields.splice(4,2, 'ecommerce_weight', 'ecommerce_qty')

      for key in fields
        p_field = form.find('.c-field-group .item-custom-field[data-field-key="'+key+'"]')
        p_field.show()
                .find('.e_skip_required')
                .removeClass('e_skip_required')
                .addClass('required')

  check_variation_status()
