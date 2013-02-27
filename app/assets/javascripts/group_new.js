
$(window).bind("load", function()
{
	$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});
	$('#selectable li').click(function(e)
	{
		$(this).toggleClass("ui-selected");
		update_id_list();	
	});
	$('#selectable').show(); //The div is initially hidden to prevent the full list from being shown before pagination. After pagination, show it
});

function update_id_list()
{
	var userIds = $.map($(".ui-selected"), function(n, i){ return parseInt(n.id); });
	$('#group_users').val(userIds);
}

