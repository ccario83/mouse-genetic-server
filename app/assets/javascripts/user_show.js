
var user_jobs_timer_id;

$(window).bind("load", function()
{

	check_user_jobs_progress();
	// Keep polling the server to update bars
	user_jobs_timer_id = setInterval('check_user_jobs_progress()', 5000);

	//$('#add-group').click(function() { location.href = "/groups/new"; });
	//$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});
	//$('#managed-groups').show(); //The div is initially hidden to prevent the full list from being shown before pagination. After pagination, show it
	
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
			error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
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
			error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
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
			error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
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
			error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
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
			error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
		});
	});
	*/
	
	/// CODE FOR CHOSEN BOXES
	$('#group_user_ids').chosen({ min_search_term_length: 2 });
	
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
	
	// Pagination link overrides
	$('#micropost-listing .pagination a').live('click', function () { update_microposts(this.href); return false;});
	$('#job-listing .pagination a').live('click', function () { update_jobs(this.href); return false;});
	$('#group-listing .pagination a').live('click', function () { update_groups(this.href); return false;});
	
	$('#collapse-datafiles').click(function() 
	{
		
		rotate(this, $(this).css('border-spacing'));
		$(this).css('border-spacing',$(this).css('border-spacing')*-1);
		$('#datafile-listing').toggle('slide', { 'direction':'up'});
	});
});



function rotate(element, deg)
{
	$(element).animate({  borderSpacing: deg },
	{
		step: function(now,fx)
		{
			$(this).css('-webkit-transform','rotate('+now+'deg)');
			$(this).css('-moz-transform','rotate('+now+'deg)'); 
			$(this).css('-ms-transform','rotate('+now+'deg)');
			$(this).css('-o-transform','rotate('+now+'deg)');
		 	$(this).css('transform','rotate('+now+'deg)');  
		},
		duration:'slow'
	},'linear');
}

function ajax_error(XMLHttpRequest, textStatus, errorThrown)
{
	//alert("Error: " + errorThrown);
}


// A function to parse url encoded parameters into a post data param associative array 
decode_url = function (url)
{
	// The disabled pagination 'previous' and 'next' still have active links ending with #. Ignore them
	if (url[url.length-1]=='#') { return null; }
	// url = url.replace('#','');
	params = {};
	terms = url.split('?')[1].split('&');
	for( i=0; i < terms.length; i++) 
	{
		pair = terms[i];
		term  = pair.split('=')[0];
		value = pair.split('=')[1];
		params[term] = value;
	};
	return params;
}

function update_groups(url)
{
	// Get url parameters
	var params = {};
	if (!(typeof(url)==='undefined'))
	{
		params = decode_url(url);
		// Dont try to post bad urls
		if (params == null) { return false; }
	}
	
	// Update groups AJAX
	$.ajax(
	{
		//async: false,
		type:'post',
		url: '/groups/reload',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: params,
		dataType: 'html',
		success: function(response) { reload_effect($('#group-listing'), response) },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	return;
}

function update_microposts(url)
{
	// Get url parameters
	var params = {};
	if (!(typeof(url)==='undefined'))
	{
		params = decode_url(url);
		// Dont try to post bad urls
		if (params == null) { return false; }
	}

	// Update microposts AJAX
	$.ajax(
	{
		//async: false,
		type:'post',
		url: '/microposts/reload',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: params,
		dataType: 'html',
		success: function(response) { reload_effect($('#micropost-listing'), response) },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	return false;
}

function update_jobs(url)
{
	// Get url parameters
	var params = {};
	if (!(typeof(url)==='undefined'))
	{
		params = decode_url(url);
		// Dont try to post bad urls
		if (params == null) { return false; }
	}
	
	// Update microposts AJAX
	$.ajax(
	{
		//async: false,
		type:'post',
		url: '/jobs/reload',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: params,
		dataType: 'html',
		success: function(response)
		{
			reload_effect($('#job-listing'), response);
			check_user_jobs_progress(); 
		},
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});

	return;
}

function check_user_jobs_progress()
{
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
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	
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
					error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
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
	
	//update_data();
	update_jobs();
	update_groups();
	update_microposts();
	
	return;
}
