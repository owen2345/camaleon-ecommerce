function cama_ecommerce_call_validator(callback){
  $.getScript('http://ajax.aspnetcdn.com/ajax/jquery.validate/1.15.0/jquery.validate.min.js', callback);
}

function cama_ecommerce_payments(){
  var panel = $('#e-payments-types');
  panel.find('form').each(function(){ $(this).validate(); });
}

function cama_checkout_actions(){
    if(!jQuery.fn.validate) return cama_ecommerce_call_validator(cama_checkout_actions);
    var panel = $('#cama_checkout_view');
    var steps = panel.find('.stepwizard-row .stepwizard-step').bind('next_step', function(){
        var link = $(this).find('a');
        var step = $(this);
        if(step.hasClass('active')) return false;
        link.removeClass('btn-default').addClass('btn-primary').parent().addClass('active').siblings().removeClass('active').find('a').removeClass('btn-primary').addClass('btn-default');
        step.prevAll().find('a').add(link).removeAttr('disabled');
        panel.find(link.attr('href')).fadeIn().siblings().hide();
        return false;
    });
    steps.find('.btn-circle').click(function(){ if(!$(this).attr('disabled')) $(this).parent().trigger('next_step'); return false; });
    steps.first().trigger('next_step');


    // billing address
    panel.find('#checkout_address_form').validate({submitHandler: function(form){
        $(form).fadeTo("fast", 0.4);
        $.post($(form).attr('action'), $(form).serialize(), function(res){
            steps.filter('.active').next().trigger('next_step');
        }).complete(function(){
            $(form).fadeTo("fast", 1);
        }).error(function(e){
            alert(e.responseText);
        });
        return false;
    }});

    // shipping form
    panel.find('#checkout_shipping_form').validate({submitHandler: function(form){
        $(form).fadeTo("fast", 0.4);
        $.post($(form).attr('action'), $(form).serialize()+'&next_step=true', function(res){
            panel.find('#step-3').html(res);
            steps.last().trigger('next_step');
        }).complete(function(){
            $(form).fadeTo("fast", 1);
        }).error(function(e){
            alert(e.responseText);
        });
        return false;
    }});

    // shipping methods
    panel.find('#shipping_methods').change(function(){
        var form = panel.find('#checkout_shipping_form');
        form.fadeTo("fast", 0.4);
        $.post(form.attr('action'), form.serialize(), function(res){
            panel.find('#product_details').html(res);
        }).complete(function(){
            form.fadeTo("fast", 1);
        }).error(function(e){
            alert(e.responseText);
        });
    }).trigger('change');

    // coupons
    panel.find('#e_coupon_apply_box input:text').keydown(function(e){ if(e.keyCode == 13){ $(this).next().find('button').click(); return false; } })
    panel.find('#e_coupon_apply_box button').click(function(){
        var btn = $(this);
        var form = panel.find('#checkout_shipping_form');
        form.fadeTo("fast", 0.4);
        $.post($('#e_coupon_apply_box').attr('data-href'), {code: panel.find('.coupon-text').val(), authenticity_token: panel.find('#e_coupon_apply_box').attr('data-token')}, function(res){
            panel.find('#product_details').html(res);
            btn.closest('#coupon').html('');
        }).error(function(e){
            alert(e.responseText);
        }).complete(function(){
            form.fadeTo("fast", 1);
        });
    });

    // copy billing address
    panel.find('#ec_copy').click(function(){
        panel.find('#shipping_address').find('input, select, textarea').each(function(){
            var id_from = $(this).attr('id').replace('shipping', 'billing');
            $(this).val($('#billing_address #'+id_from).val())
        });
        return false;
    });
}
