
var user_jobs_timer_id;

$(window).bind("load", function()
{

	check_user_jobs_progress();
	// Keep polling the server to update bars
	user_jobs_timer_id = setInterval('check_user_jobs_progress()', 5000);

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
			success: function(response) {post_group_change(response)},
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
			success: function(response) {post_group_change(response)},
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
			success: function(response) {post_group_change(response)},
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
			success: function(response) {post_group_change(response)},
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
	$('#micropost-listing .pagination a').live('click', function () { update_div('#micropost-listing','/microposts/reload', this.href); return false;});
	$('#job-listing .pagination a').live('click', function () { update_div('#job-panel','/jobs/reload', this.href); return false;});
	$('#group-listing .pagination a').live('click', function () { update_div('#group-panel','/groups/reload', this.href); return false;});
	$('#datafile-listing .pagination a').live('click', function () { update_div('#datafile-panel','/datafiles/reload', this.href); return false;});
	
	// Collapse functions
	$('#collapse-groups').live('click', function() { collapse_listing(this, '#group-listing'); });
	$('#collapse-datafiles').live('click', function() { collapse_listing(this, '#datafile-listing'); });
	$('#collapse-jobs').live('click', function() { collapse_listing(this, '#job-listing'); });
	$('#collapse-microposts').live('click', function() { collapse_listing(this, '#micropost-listing'); });

	rotate($('#collapse-groups'), 0, -5, -90);
	rotate($('#collapse-datafiles'), 0, -5, -90);
	rotate($('#collapse-jobs'), 0, -5, -90);
});
function ajax_error(XMLHttpRequest, textStatus, errorThrown)
{
	alert("Error: " + errorThrown);
}



/* Functions to pull out for shared custom ajax js file */

function collapse_listing(arrow, div)
{
	if (getRotationDegrees($(arrow))==-90) { rotate(arrow, -90, 5, 0); } else { rotate(arrow, 0, -5, -90); }
	//$(div).toggle('slide', { 'direction':'up'});
	
	if ($(div).is(":hidden"))
	{
		$(div).slideDown();
	} else {
		$(div).slideUp();
	}
}


function rotate(element, cur_deg, step, final_deg)
{
	cur_deg = cur_deg + step;
	$(element).css({ '-webkit-transform': 'rotate(' + cur_deg + 'deg)'});
	$(element).css({ '-moz-transform': 'rotate(' + cur_deg + 'deg)'});
	$(element).css({ '-ms-transform': 'rotate(' + cur_deg + 'deg)'});
	$(element).css({ '-o-transform': 'rotate(' + cur_deg + 'deg)'});
	$(element).css({ 'transform': 'rotate(' + cur_deg + 'deg)'});
	
	if ((step > 0 && cur_deg < final_deg) || (step < 0 && cur_deg > final_deg))
	{
		setTimeout(function() { rotate(element, cur_deg, step, final_deg); }, 10);
	} else {return;}
}
// Needed to find the degrees rotated so the rotate direction can be figured out
function getRotationDegrees(obj)
{
	var matrix = obj.css("-webkit-transform") ||
	obj.css("-moz-transform")    ||
	obj.css("-ms-transform")     ||
	obj.css("-o-transform")      ||
	obj.css("transform");
	if(matrix !== 'none')
	{
		var values = matrix.split('(')[1].split(')')[0].split(',');
		var a = values[0];
		var b = values[1];
		var angle = Math.round(Math.atan2(b, a) * (180/Math.PI));
	} else { var angle = 0; }
	return angle;
}


// A function to parse url encoded parameters into a post data param associative array 
function decode_url(url)
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

function update_div(target_div, update_url, url_params)
{
	// Get url parameters
	var params = {};
	if (!(typeof(url_params)==='undefined'))
	{
		params = decode_url(url_params);
		// Dont try to post bad urls
		if (params == null) { return false; }
	}
	
	// Update groups AJAX
	$.ajax(
	{
		//async: false,
		type:'post',
		url: update_url,
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: params,
		dataType: 'html',
		success: function(response) { reload_effect($(target_div), response); after_update(); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	return;
}
function reload_effect(div, new_html)
{
	div.html(new_html);
	div.find('ol').effect("highlight", {color: '#FCF8E3'}, 1000);
	div.find('ul').effect("highlight", {color: '#FCF8E3'}, 1000);
	return;
}

/* End pull out */


function after_update()
{
	check_user_jobs_progress();
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
		var selector = '.jobs li #' + k.toString() + '.bar';
		var width = v.toString() + '%'
		$(selector).css("width",width)
	});
	
	return;
}

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
	
	update_div('#group-panel','/groups/reload', this.href);
	update_div('#datafile-panel','/datafiles/reload', this.href);
	update_div('#job-panel','/jobs/reload', this.href);
	update_div('#micropost-panel','/microposts/reload', this.href);
	
	return;
}
