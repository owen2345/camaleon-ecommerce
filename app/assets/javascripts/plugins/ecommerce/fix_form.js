/**
 * Created by Froilan on 02/09/2015.
 */
jQuery(function($){
    $( '#form-post' ).on( "change", '.editor-custom-fields input[name="field_options[ecommerce_weight][values][]"], .editor-custom-fields .input-value.number', function() {
        setTimeout(function(){
            $(this).val(Math.abs($(this).val()) || 0);
        }.bind(this), 60)
    });
});