function cama_ecommerce_call_validator(callback){
  $.getScript('http://ajax.aspnetcdn.com/ajax/jquery.validate/1.15.0/jquery.validate.min.js', callback);
}

function cama_ecommerce_shopping_cart(){
  if(!jQuery.fn.validate) return cama_ecommerce_call_validator(cama_ecommerce_shopping_cart);
  $('#table-shopping-cart td .text-qty').change(function(){
    if ($(this).val() < 1) return false;
    var total = $('#table-shopping-cart tbody tr').map(function(){
      var $tr = $(this);
      var price = parseFloat($tr.find('td[data-price]').attr('data-price'));
      var tax =  parseFloat($tr.find('td[data-tax]').attr('data-tax'));
      var qty =  parseFloat($tr.find('td[data-qty] input.text-qty').val());
      if(qty < 0) qty = 0;
      var subtotal = (price + tax) * qty;
      $tr.find('td[data-subtotal]').html('$'+subtotal.toFixed(2))
      return subtotal;
    }).get().reduce(function(a, b) { return a + b; }, 0);
    $('#table-shopping-cart #total').html('$'+total.toFixed(2))
  })
}

function cama_ecommerce_payments(){
  if(!jQuery.fn.validate) return cama_ecommerce_call_validator(cama_ecommerce_payments);
  var panel = $('#select_payment_view');
  panel.find('form').each(function(){ $(this).validate(); });
}

function cama_checkout_actions(){
  if(!jQuery.fn.validate) return cama_ecommerce_call_validator(cama_checkout_actions);
  var panel = $('#cama_checkout_view');
  panel.find('form').validate();
  panel.find('#ec_copy').click(function(){
    panel.find('#shipping_address').find('input, select, textarea').each(function(){
      var id_from = $(this).attr('id').replace('shipping', 'billing');
      $(this).val($('#billing_address #'+id_from).val())
    })
    return false;
  });

  function set_total_amount(){
    var value = parseFloat(panel.find('#shipping_methods option:checked').attr('data-price'));
    var pre_total = parseFloat(panel.find('#order_total').attr('data-total'));
    var dis = panel.find('#coupon_application_total').attr('data-amount');
    panel.find('#shipping_total span').html(value.toFixed(2));
    if(dis == 'free'){
      panel.find('#order_total span').html(0);
      panel.find('#shipping_total').parent().slideUp('slow')
    }else{
      panel.find('#shipping_total').parent().slideDown('slow')
      var total_final = (value + pre_total - parseFloat(dis)).toFixed(2);
      panel.find('#order_total span').html(total_final);
    }
  }

  panel.find('#shipping_methods').change(function(){ set_total_amount();  });
  panel.find('#e_coupon_apply_box input:text').keydown(function(e){ if(e.keyCode == 13){ $(this).next().find('button').click(); return false; } })
  panel.find('#e_coupon_apply_box button').click(function(){
    var code = panel.find('.coupon-text').val();
    $.post($('#e_coupon_apply_box').attr('data-href'), {code: code, authenticity_token: $('#e_coupon_apply_box').attr('data-token')}, function(res){
        panel.find('#coupon_application_total').attr('data-amount', res.discount_type == 'free' ? 'free' : res.discount);
        panel.find('#coupon_application_row').show().find('#coupon_application_total span').html(res.text);
        panel.find('#coupon_code').val(res.code);
        panel.find('.coupon-text').prop('readonly', true).next().hide().next().removeClass('hidden');
        set_total_amount();
    }, 'json').error(function(e){
        alert(e.responseText);
    });
  });
}
