//= require ./jquery.multi-select
//= require_self
jQuery(function(){
    var form = $('#ecommerce_settings_form');
    form.find('select[multiple], .masked_select').not('#setting_visitor_unit_currencies, #setting_shipping_countries').selectpicker();
    form.find('#setting_visitor_unit_currencies').multiSelect({keepOrder: true});
    form.find('#setting_shipping_countries').multiSelect();
    setTimeout(function(){ form.find('textarea.editor.translate-item').tinymce(cama_get_tinymce_settings({height: 220})) }, 100);
});
