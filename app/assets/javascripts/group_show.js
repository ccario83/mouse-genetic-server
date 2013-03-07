
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

	$('.task').click(function() { $(this).toggleClass('icon-check');  $(this).toggleClass('icon-check-empty'); });
});

$(function() {
$('#duedate').datetimepicker({
	language: 'en',
	pick12HourFormat: true
});
});
