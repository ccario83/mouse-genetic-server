// requires ajax_and_pizzaz.js
var user_jobs_timer_id;

$(window).bind("load", function()
{

	//----------- #group-panel/#edit-groups listeners -------------------------------------------------
	// AJAX handlers for icon clicks
	$('#edit-groups-listings .icon-panel i.accept').live('click', function(){ group_change('accept', $(this)[0].id) });
	$('#edit-groups-listings .icon-panel i.decline').live('click', function(){ group_change('decline', $(this)[0].id) });
	$('#edit-groups-listings .icon-panel i.leave').live('click', function(){ group_change('leave', $(this)[0].id) });
	$('#edit-groups-listings .icon-panel i.delete').live('click', function(){ group_change('delete', $(this)[0].id) });
	$('#group_user_ids').chosen({ min_search_term_length: 2 });
	attach_submit('#new-group');
	//------------------------------------------------------------------------------------------------

	//----------- #datafile-panel listeners ----------------------------------------------------------
	$('.edit_datafile_groups').each(function() { $(this).chosen({ min_search_term_length: 2 }); })
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
	attach_submit('#new-datafile');
	$("[id^=edit-datafile]").each(function() { attach_submit(this.id); });
	//------------------------------------------------------------------------------------------------
	
	
	//----------- #job-panel listeners ---------------------------------------------------------------
	$('.edit_job_groups').each(function() { $(this).chosen({ min_search_term_length: 2 }); })
	$("[id^=edit-job]").each(function() { attach_submit(this.id); });
	//------------------------------------------------------------------------------------------------


	//----------- #micropost-panel listeners ---------------------------------------------------------
	// Chosen listeners
	$('#group_user_ids').chosen({ min_search_term_length: 2 });
	$('#micropost_group_recipient_ids').chosen({ min_search_term_length: 2 });
	$('#micropost_user_recipient_ids').chosen({ min_search_term_length: 2 });
	
	// Set the selected To: box to groups initially
	$('#micropost_user_recipient_ids_chzn').hide();
	$('#micropost_recipient_type').val('group');
	
	// Switches to: box between group and user recipients 
	$('#to-group').live('click', function() 
	{
		$('#to-group').toggleClass("highlighted");
		$('#to-user').toggleClass("highlighted");
		$("#micropost_group_recipient_ids_chzn").toggle();
		$("#micropost_user_recipient_ids_chzn").toggle();
		$('#micropost_recipient_type').val('group');
	});
	$('#to-user').live('click', function() 
	{
		$('#to-group').toggleClass("highlighted");
		$('#to-user').toggleClass("highlighted");
		$("#micropost_group_recipient_ids_chzn").toggle();
		$("#micropost_user_recipient_ids_chzn").toggle();
		$('#micropost_recipient_type').val('user');
	});
	attach_submit('#new-micropost');
	//------------------------------------------------------------------------------------------------


	//----------- will_paginate overrides for AJAX  --------------------------------------------------
	// Pagination link overrides
	$('#micropost-listing .pagination a').live('click', function () { update_div('#micropost-panel', this.href, '/microposts/reload'); return false;});
	$('#job-listing .pagination a').live('click', function () { update_div('#job-panel', this.href, '/jobs/reload'); return false;});
	$('#group-listing .pagination a').live('click', function () { update_div('#group-panel', this.href, '/groups/reload'); return false;});
	$('#datafile-listing .pagination a').live('click', function () { update_div('#datafile-panel', this.href, '/datafiles/reload'); return false;});
	
	// Collapse functions
	$('#collapse-groups').live('click', function() { collapse_listing(this, '#group-listing', this); });
	$('#group-panel .title-panel').live('click', function() { collapse_listing($('#collapse-groups'), '#group-listing'); });
	$('#collapse-datafiles').live('click', function() { collapse_listing(this, '#datafile-listing'); });
	$('#datafile-panel .title-panel').live('click', function() { collapse_listing($('#collapse-datafiles'), '#datafile-listing'); });
	$('#collapse-jobs').live('click', function() { collapse_listing(this, '#job-listing'); });
	$('#job-panel .title-panel').live('click', function() { collapse_listing($('#collapse-jobs'), '#job-listing'); });
	$('#collapse-microposts').live('click', function() { collapse_listing(this, '#micropost-listing'); });
	$('#micropost-panel .title-panel').live('click', function() { collapse_listing($('#collapse-microposts'), '#micropost-listing'); });
	
	// Initally collapse groups, datafiles, and jobs
	rotate($('#collapse-groups'), 0, -5, -90);
	rotate($('#collapse-datafiles'), 0, -5, -90);
	rotate($('#collapse-jobs'), 0, -5, -90);
	//-------------------------------------------------------------------------------------------------
	
	// Keep polling the server to update job progress bars
	//user_jobs_timer_id = setInterval('check_jobs_progress()', 5000);
	check_jobs_progress();
});

// Error function called on any AJAX fails
function ajax_error(XMLHttpRequest, textStatus, errorThrown)
{
	alert("Error: " + errorThrown);
}

function after_update_div()
{
	check_jobs_progress();
}



function group_change(type, id)
{
	var url = null;
	switch(type)
	{
		case 'accept':
			url = '/users/accept_group'
		break;
		
		case 'decline':
			url = '/users/decline_group'
		break;
		
		case 'leave':
			url = '/users/leave_group'
		break;
		
		case 'delete':
			url = '/users/delete_group'
		break;
	};
	// other cases ignored
	if (url==null) { return; }
	$.ajax(
	{
		//async: false,
		type:'post',
		url: url,
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: {id: id},
		dataType: 'json',
		success: function(response) {post_group_change(response)},
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	
};

function post_group_change(response)
{
	switch(response['type'])
	{
		case 'accept':
			// Disable Accept
			$('#'+response['id']+'.accept').addClass('disabled');
			$('#'+response['id']+'.accept').unbind('click');
			$('#'+response['id']+'.accept').removeClass('accept');
			
			// Disable Decline
			$('#'+response['id']+'.decline').addClass('disabled');
			$('#'+response['id']+'.decline').unbind('click');
			$('#'+response['id']+'.decline').removeClass('decline');
			
			// Enable Leave
			$('#'+response['id']+'.icon-signout').addClass('leave');
			$('#'+response['id']+'.leave').removeClass('disabled');
			$('#'+response['id']+'.leave').click(function()
			{
				var id = $(this)[0].id;
				$.ajax(
				{
					// Send the request as a get to the url /phenotypes/query
					//async: false,
					type:'post',
					url: '/users/leave_group',
					headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
					data: {id: id},
					dataType: 'json',
					success: function(response) {post_group_change(response)},
					error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
				});
			});
			
			// Solidify group icon
			$('#'+response['id']+'.icon-group').removeClass('faded');
			var row = $('#'+response['id']+'.listing-panel')[0];
			
			// Flash success
			$(row).animate({backgroundColor:'#DFF0D8'},'fast');
			$(row).animate({backgroundColor:'white'},'fast');
		break;
		
		case 'decline':
			$('#'+response['id']+'.decline').addClass('disabled');
			$('#'+response['id']+'.decline').unbind('click');
			$('#'+response['id']+'.decline').removeClass('decline');

			var row = $('#'+response['id']+'.listing-panel')[0];
			$(row).fadeOut('slow');
		break;
		
		case 'leave':
			$('#'+response['id']+'.leave').addClass('disabled');
			$('#'+response['id']+'.leave').unbind('click');
			$('#'+response['id']+'.leave').removeClass('leave');

			var row = $('#'+response['id']+'.listing-panel')[0];
			$(row).fadeOut('slow');
		break;
		
		case 'delete':
			$('#'+response['id']+'.delete').addClass('disabled');
			$('#'+response['id']+'.delete').unbind('click');
			$('#'+response['id']+'.delete').removeClass('delete');

			var row = $('#'+response['id']+'.listing-panel')[0];
			$(row).animate({backgroundColor:'#f2dede'},'fast');
			$(row).animate({backgroundColor:'white'},'fast');
			$(row).fadeOut('slow');
		break;
	}

	update_div('#group-panel', this.href, '/groups/reload', true);
	//update_div('#micropost-panel', this.href, '/microposts/reload');
	
	return;
}
