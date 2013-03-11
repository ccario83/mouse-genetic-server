
$(window).bind("load", function()
{
	// Enable pagniation (client-side) with bootstrap theming for the pagination container
	$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});

	// Sets a click listener for every user
	$('#selectable-users li').click(function(e)
	{
		// First style the element so the end-user knows their click was registered
		$(this).toggleClass("ui-selected");
		// Get all selected users by ID
		var userIds = $.map($(".ui-selected"), function(n, i){ return parseInt(n.id); });
		// Add their IDs to the group_users input ID, which was created by rails and simple_form to handle the submitted user list
		$('#group_users').val(userIds);	
	});
	//The div is initially hidden to prevent the full list from being shown before pagination. Pagination is done rendering now, so show the list
	$('#selectable-users').show(); 

	// Populate the group_user list with any values sent from the server (found in the #preselected-users hidden input in the multi_select partial)
	$('#group_users').val($('#preselected-users').val());
	
	// Style the preselected users so that they appear selected ot the end-user
	var userIds = jQuery.parseJSON($('#preselected-users').val());
	for (var i = 0; i< userIds.length; i++)
	{
		$('#selectable-users li#'+userIds[i]).addClass("ui-selected");
	}
});


