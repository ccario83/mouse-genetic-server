
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
		
		// Rehide unselected users (REMOVE FOR PAGINATION)
		$('#selectable-users li').hide();
		$(".ui-selected").show();
	});
	
	//The div is initially hidden to prevent the full list from being shown before pagination. Pagination is done rendering now, so show the list
	$('#selectable-users').show(); 

	// Populate the group_user list with any values sent from the server (found in the #preselected-users hidden input in the multi_select partial)
	$('#group_users').val($('#preselected-users').val());
	
	
	// Hide all users (REMOVE FOR PAGINATION)
	$('#selectable-users li').hide();
	
	// Style the preselected users so that they appear selected ot the end-user
	var userIds = jQuery.parseJSON($('#preselected-users').val());
	for (var i = 0; i< userIds.length; i++)
	{
		$('#selectable-users li#'+userIds[i]).addClass("ui-selected").show;
	}
	
	
	var user_list=[];
	var users = $('.ui-selectee > div > a');
	for (var i = 0; i < users.length; i++)
		user_list.push({'value': i, 'label': users[i].text});
	$('#user_search').autocomplete(
	{ 
		source: user_list, 
		minLength: 3, 
		select: function(event, ui)
		{
			var user_container = $(users[ui.item.value]).parent().parent();
			user_container.show();
			// First style the element so the end-user knows their click was registered
			user_container.toggleClass("ui-selected");
			// Get all selected users by ID
			var userIds = $.map($(".ui-selected"), function(n, i){ return parseInt(n.id); });
			// Add their IDs to the group_users input ID, which was created by rails and simple_form to handle the submitted user list
			$('#group_users').val(userIds);	
			return false; // Return false to cancel the event, which prevents jQuery from replacing the field with the 'value' (which is just the ID)
		}
	});


});

