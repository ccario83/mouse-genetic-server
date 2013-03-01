
$(window).bind("load", function()
{
	$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});
	$('#selectable-users li').click(function(e)
	{
		$(this).toggleClass("ui-selected");
		var userIds = $.map($(".ui-selected"), function(n, i){ return parseInt(n.id); });
		$('#group_users').val(userIds);	
	});
	$('#selectable-users').show(); //The div is initially hidden to prevent the full list from being shown before pagination. After pagination, show it

	$('#group_users').val($('#preselected_users').val());	
	var userIds = jQuery.parseJSON($('#preselected_users').val());
	for (var i = 0; i< userIds.length; i++)
	{
		$('#selectable-users li#'+userIds[i]).addClass("ui-selected");
	}
});

