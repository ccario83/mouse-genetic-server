
var user_jobs_timer_id;

$(window).bind("load", function()
{

	check_user_jobs_progress();
	// Keep polling the server to update bars
	user_jobs_timer_id = setInterval('check_user_jobs_progress()', 5000);

	$('#add-group').click(function() { location.href = "/groups/new"; });
	$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});
	$('#managed-groups').show(); //The div is initially hidden to prevent the full list from being shown before pagination. After pagination, show it
	$('.pulsate').click(function() { $(this).removeClass('pulsate')  });
	
	$(function()
	{
		// Self-executing recursive animation
		(function pulse(){
			$('.pulsate').delay(200).fadeOut('slow').delay(50).fadeIn('slow',pulse);
		})();
	});
	
	$('.icon-panel i.accept').click(function()
	{
		var id = $(this)[0].id;
		$.ajax(
		{
			//async: false,
			type:'post',
			url: '/users/accept_group',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'json',
			success: function(response) {process_response(response)},
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
		
	});
	
	$('.icon-panel i.decline').click(function()
	{
		var id = $(this)[0].id;
		$.ajax(
		{
			//async: false,
			type:'post',
			url: '/users/decline_group',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'json',
			success: function(response) {process_response(response)},
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
		
	});
	
	$('.icon-panel i.leave').click(function()
	{
		var id = $(this)[0].id;
		$.ajax(
		{
			//async: false,
			type:'post',
			url: '/users/leave_group',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'json',
			success: function(response) {process_response(response)},
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
		
	});
	
	$('.icon-panel i.delete').click(function()
	{
		var id = $(this)[0].id;
		$.ajax(
		{
			//async: false,
			type:'post',
			url: '/users/delete_group',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'json',
			success: function(response) {process_response(response)},
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
		
	});
	
	/* Jobs AJAX call
	$('.jobs .display').click(function() {
		var id = this.id;
		$.ajax(
		{
			//async: false,
			type:'post',
			url: '/users/job',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'HTML',
			success: function(html){ $("#center-panel").html(html); },
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
	});
	*/
	
	/// CODE FOR CHOSEN BOXES
	
	// To handle user and group token passing 
	$('#micropost_group_recipient_ids').chosen({ min_search_term_length: 2 });
	
		// To handle user and group token passing 
	$('#micropost_user_recipient_ids').chosen({ min_search_term_length: 2 });
	
	$('#micropost_user_recipient_ids_chzn').hide();
	$('#micropost_recipient_type').val('group');
	
	$('#to-group').click(function() 
	{
		$('#to-group').toggleClass("highlighted");
		$('#to-user').toggleClass("highlighted");
		$("#micropost_group_recipient_ids_chzn").toggle();
		$("#micropost_user_recipient_ids_chzn").toggle();
		$('#micropost_recipient_type').val('group');
	});
	$('#to-user').click(function() 
	{
		$('#to-group').toggleClass("highlighted");
		$('#to-user').toggleClass("highlighted");
		$("#micropost_group_recipient_ids_chzn").toggle();
		$("#micropost_user_recipient_ids_chzn").toggle();
		$('#micropost_recipient_type').val('user');
	});
});

// Force the pagination links to use AJAX methods
$(function()
{
	$('#micropost-listing .pagination a').live('click', function () { update_microposts(this.href); return false;});
	$('#job-listing .pagination a').live('click', function () { update_jobs(this.href); return false;});
	$('#group-listing .pagination a').live('click', function () { update_groups(this.href); return false;});
});

function check_user_jobs_progress(url)
{
	// Get the page number from the url
	var page_num = null
	if (!(typeof(url)==='undefined')) page_num = url.split('=')[1];

	// Get the job ids
	var job_ids = []
	$('.jobs li .bar').each(function() { job_ids.push(parseInt(this.id)) });
	
	$.ajax(
	{
		// Send the request as a get to the url /progress/job_id (routes.rb will send this to uwf#progress with :data = id
		type:'post',
		url: '/jobs/percentages/', // job_id embedded as a hidden span
		datatype: 'json',
		data: {ids: JSON.stringify(job_ids)},
		success: update_job_bars,
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert('Error: ' + errorThrown); clearInterval(uwf_timer_id);},
	});
	
}

function update_groups(url)
{
	// Get the page number from the url
	var page_num = null
	if (!(typeof(url)==='undefined')) page_num = url.split('=')[1];

	// Update groups AJAX
	$.ajax(
	{
		//async: false,
		type:'post',
		url: '/groups/reload',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: { 'groups_paginate': page_num},
		dataType: 'html',
		success: function(response) { reload_effect($('#group-listing'), response) },
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
	});
	return;
}

function update_microposts(url)
{
	// Get the page number from the url
	var page_num = null
	if (!(typeof(url)==='undefined')) page_num = url.split('=')[1];

	// Update microposts AJAX
	$.ajax(
	{
		//async: false,
		type:'post',
		url: '/microposts/reload',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: { 'microposts_paginate': page_num},
		dataType: 'html',
		success: function(response) { reload_effect($('#micropost-listing'), response) },
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
	});
	return false;
}

function update_jobs(url)
{
	// Get the page number from the url
	var page_num = null
	if (!(typeof(url)==='undefined')) page_num = url.split('=')[1];

	// Update microposts AJAX
	$.ajax(
	{
		//async: false,
		type:'post',
		url: '/jobs/reload',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: { 'jobs_paginate': page_num},
		dataType: 'html',
		success: function(response) { reload_effect($('#jobs-listing'), response) },
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
	});
	return;
}

function update_job_bars(percentages)
{
	$.each(percentages, function(k,v)
	{
		var selector = '.jobs li .bar#' + k.toString();
		var width = v.toString() + '%'
		$(selector).css("width",width)
	});
	
	return;
}

function reload_effect(div, new_html)
{
	
	//div.toggle('slide', { direction : 'left' });
	div.html(new_html);
	div.find('ol').effect("highlight", {color: '#FCF8E3'}, 1000);
	div.find('ul').effect("highlight", {color: '#FCF8E3'}, 1000);
	//div.toggle('slide', { direction : 'right' });
	return;
}


function process_response(response)
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
					success: function(response) {process_response(response)},
					error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
				});
			});
			
			// Solidify group icon
			$('#'+response['id']+'.icon-group').removeClass('faded');
			var row = $('#'+response['id']+'.group-management-panel')[0];
			
			// Flash success
			$(row).animate({backgroundColor:'#DFF0D8'},'fast');
			$(row).animate({backgroundColor:'white'},'fast');
		break;
		
		case 'decline':
			$('#'+response['id']+'.decline').addClass('disabled');
			$('#'+response['id']+'.decline').unbind('click');
			$('#'+response['id']+'.decline').removeClass('decline');

			var row = $('#'+response['id']+'.group-management-panel')[0];
			$(row).fadeOut('slow');
		break;
		
		case 'leave':
			$('#'+response['id']+'.leave').addClass('disabled');
			$('#'+response['id']+'.leave').unbind('click');
			$('#'+response['id']+'.leave').removeClass('leave');

			var row = $('#'+response['id']+'.group-management-panel')[0];
			$(row).fadeOut('slow');
		break;
		
		case 'delete':
			$('#'+response['id']+'.delete').addClass('disabled');
			$('#'+response['id']+'.delete').unbind('click');
			$('#'+response['id']+'.delete').removeClass('delete');

			var row = $('#'+response['id']+'.group-management-panel')[0];
			$(row).animate({backgroundColor:'#f2dede'},'fast');
			$(row).animate({backgroundColor:'white'},'fast');
			$(row).fadeOut('slow');
		break;
	}
	
	update_data();
	update_jobs();
	update_groups();
	update_microposts();
	
	return;
}
