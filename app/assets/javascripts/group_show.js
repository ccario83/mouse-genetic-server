// Clinton Cario
// 7/3/2013

$(window).bind("load", function()
{
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
	
	
	//----------- #member-panel listeners ---------------------------------------------------------------
	// Initialize chosen boxes for shared groups selection in the edit job modals
	$('#edit-group-members').chosen({ min_search_term_length: 2 });
	// Attach submit buttons to the edit group modals
	attach_submit('#edit-members');
	//------------------------------------------------------------------------------------------------


	//----------- #datafile-panel listeners ----------------------------------------------------------
	$(".edit_datafile_groups:input:not([type='hidden'])").each(function() { $(this).chosen({ min_search_term_length: 2 }); });
	// A quick filter on a new datafile selection to make sure the file is valid and less than 1Mb. Only attaches the form submit button if the file looks OK
	$('#new-datafile :file').change(function()
	{
		var file = this.files[0];
		if(file.name.length < 1 || file.size < 1) 
		{
			alert("The file appears empty.");
			$('#new-datafile :submit').attr('disabled','disabled');
		}
		else if(file.size > 1048576)
		{
			alert("Please limit file uploads to 1Mb.");
			$('#new-datafile :submit').attr('disabled','disabled');
		}
		else
		{
			$('#new-datafile :submit').removeAttr('disabled','');
			$('#new-datafile :submit').live('click', function(){ ajax_form_submit('#new-datafile'); return false; });
		}
	});
	// Attach the datafile submit on load.
	attach_submit('#new-datafile');
	// Attach form submit buttons to all edit modals. 
	$("[id^=edit-datafile]").each(function() { attach_submit(this.id); });
	//------------------------------------------------------------------------------------------------
	
	
	//----------- #job-panel listeners ---------------------------------------------------------------
	// Initialize chosen boxes for shared groups selection in the edit job modals
	$('.edit_job_groups').each(function() { $(this).chosen({ min_search_term_length: 2 }); })
	// Attach submit buttons to the edit group modals
	$("[id^=edit-job]").each(function() { attach_submit(this.id); });
	//------------------------------------------------------------------------------------------------
	
	
	//----------- #micropost-panel listeners ---------------------------------------------------------
	// Attach a submit to the new-micropost modal
	attach_submit('#new-micropost');
	//------------------------------------------------------------------------------------------------
	
	
	//----------- #task-panel listeners ----------------------------------------------------------
	$('.task').live('click',function()
	{ 
		// If this element has the 'gray' class, its because rails added it to indicate state should not change.
		// Only the task creator and assignee can modify this state (this is also checked by rails after the AJAX call)
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
	// Attach the datatimepicker jQuery plugin to the date field
	$('#duedate').datetimepicker(
	{
		language: 'en',
		format: 'yyyy-MM-dd hh:mm',
		pick12HourFormat: false,
		pickSeconds: false
	});
	// Attach the submit button to the new-task form
	attach_submit('#new-task');
	//------------------------------------------------------------------------------------------------
	
	
	//----------- will_paginate overrides for AJAX  --------------------------------------------------
	// Pagination link overrides (we would like to call an AJAX update_div function instead of a GET request for a new page)
	$('#member-listing .pagination a').live('click', function () { update_div('#member-panel', this.href, '/members/reload'); return false;});
	$('#datafile-listing .pagination a').live('click', function () { update_div('#datafile-panel', this.href, '/datafiles/reload'); return false;});
	$('#job-listing .pagination a').live('click', function () { update_div('#job-panel', this.href, '/jobs/reload'); return false;});
	$('#micropost-listing .pagination a').live('click', function () { update_div('#micropost-listing', this.href, '/microposts/reload'); return false;});
	$('#task-listing .pagination a').live('click', function () { update_div('#task-panel', this.href, '/tasks/reload'); return false;});
	
	// Collapse functions (attach collpase/expand functionality to the arrows and panel titles)
	$('#collapse-members').live('click', function() { collapse_listing(this, '#member-listing'); });
	$('#member-panel .title-panel').live('click', function() { collapse_listing($('#collapse-members'), '#member-listing'); });
	$('#collapse-datafiles').live('click', function() { collapse_listing(this, '#datafile-listing'); });
	$('#datafile-panel .title-panel').live('click', function() { collapse_listing($('#collapse-datafiles'), '#datafile-listing'); });
	$('#collapse-jobs').live('click', function() { collapse_listing(this, '#job-listing'); });
	$('#job-panel .title-panel').live('click', function() { collapse_listing($('#collapse-jobs'), '#job-listing'); });
	$('#collapse-microposts').live('click', function() { collapse_listing(this, '#micropost-listing'); });
	$('#micropost-panel .title-panel').live('click', function() { collapse_listing($('#collapse-microposts'), '#micropost-listing'); });
	$('#collapse-tasks').live('click', function() { collapse_listing(this, '#task-listing'); });
	$('#task-panel .title-panel').live('click', function() { collapse_listing($('#collapse-tasks'), '#task-listing'); });

	// Set the arrows to the collapsed state
	rotate($('#collapse-members'), 0, -5, -90);
	rotate($('#collapse-datafiles'), 0, -5, -90);
	rotate($('#collapse-jobs'), 0, -5, -90);
	//-------------------------------------------------------------------------------------------------
	
	// Keep polling the server to update job progress bars
	//user_jobs_timer_id = setInterval('check_jobs_progress()', 5000);
	check_jobs_progress();
});

// Display any AJAX errors
function ajax_error(XMLHttpRequest, textStatus, errorThrown)
{
	//alert("Error: " + errorThrown);
}

// Overrides ajax_and_pizzaz's function and is run after the update_div function successfully runs
function after_update_div()
{
	check_jobs_progress();
}
