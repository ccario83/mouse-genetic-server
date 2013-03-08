
$(window).bind("load", function()
{
	//$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});
	//$('#selectable').show(); //The div is initially hidden to prevent the full list from being shown before pagination. After pagination, show it

	$('#add-task').click(function() {
		$('#new-task').show();
	});


	/* Truncate the group description if needed */
	$('#group-description').jTruncate({  
		length: 15,
		minTrail: 5,
		moreText: "[show]",
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
