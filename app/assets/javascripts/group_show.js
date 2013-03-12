
$(window).bind("load", function()
{
	//$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});
	//$('#selectable').show(); //The div is initially hidden to prevent the full list from being shown before pagination. After pagination, show it

	/* Truncate the group description if needed */
	$('#group-description').jTruncate({  
		length: 15,
		minTrail: 5,
		moreText: '[more]',
		lessText: "[hide]",
		ellipsisText: "...",
		moreAni: 0,
		lessAni: 0,
	});

	$('.task').click(function()
	{ 
		// If this element has the 'gray' class, its because rails added it to indicate its state should not change.
		// Only the task creator and assignee can modify this state (this is also checked by rails after the AJAX call 
		if (!($(this).hasClass('gray')))
		{
			var id  = parseInt($(this)[0].id);
			var box = $(this);
			$.ajax(
			{
				// Send the request as a get to the url /tasks/check
				//async: false,
				type:'post',
				url: '/tasks/check',
				headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
				data: { id: id },
				dataType: 'json',
				success: function(id) 
				{
					var selector = '#' + id + '.task';
					$(selector).toggleClass('icon-check');  
					$(selector).toggleClass('icon-check-empty');
				},
				error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
			});
		}
	});
	
	
	/*-------------------------
	 For the user-manage modal
	---------------------------*/
	// Enable pagniation (client-side) with bootstrap theming for the pagination container
	$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});

	// Sets a click listener for every user
	$('#selectable-users li').click(function(e)
	{
		// First style the element so the end-user knows their click was registered
		$(this).toggleClass("ui-selected");
		// Get all selected users by ID
		var userIds = $.map($(".ui-selected"), function(n, i){ return parseInt(n.id); });
		// Add their IDs to the modified_member_users input ID, which was created by rails and simple_form to handle the submitted user list
		$('#modified_users').val(userIds);	
	});
	//The div is initially hidden to prevent the full list from being shown before pagination. Pagination is done rendering now, so show the list
	$('#selectable-users').show(); 

	// Populate the modified_member_users list with any values sent from the server (found in the #preselected-users hidden input in the multi_select partial)
	$('#modified_users').val($('#preselected-users').val());
	
	// Style the preselected users so that they appear selected ot the end-user
	var userIds = jQuery.parseJSON($('#preselected-users').val());
	for (var i = 0; i< userIds.length; i++)
	{
		$('#selectable-users li#'+userIds[i]).addClass("ui-selected");
	}
	/* -------------------- */
});


$(function()
{
	$('#duedate').datetimepicker(
	{
		language: 'en',
		format: 'yyyy-MM-dd hh:mm',
		pick12HourFormat: false,
		pickSeconds: false
	});
});
