

<% flash.each do |alert_type, notice| %>
flash_notice("<%= notice %>", "<%= alert_type %>");
<% end %>

$("#image-parameters").html("<%= escape_javascript(render :partial => 'uwf/image_params_table', :locals => { params: @params, show_image_params: true }) %>");
