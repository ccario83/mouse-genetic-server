
$(window).bind("load", function()
{
	$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});
	$('#selectable li').click(function(e) {$(this).toggleClass("ui-selected");});
	$('#selectable').show(); //The div is initially hidden to prevent the full list from being shown before pagination. After pagination, show it
});


