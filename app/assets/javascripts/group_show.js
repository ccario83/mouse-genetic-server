
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
	
	// Pagination link overrides
	$('#member-listing .pagination a').live('click', function () { update_div('#member-panel','/members/reload', this.href); return false;});
	$('#datafile-listing .pagination a').live('click', function () { update_div('#datafile-panel','/datafiles/reload', this.href); return false;});
	$('#job-listing .pagination a').live('click', function () { update_div('#job-panel','/jobs/reload', this.href); return false;});
	$('#micropost-listing .pagination a').live('click', function () { update_div('#micropost-listing','/microposts/reload', this.href); return false;});
	$('#task-listing .pagination a').live('click', function () { update_div('#task-panel','/tasks/reload', this.href); return false;});
	
	// Collapse functions
	$('#collapse-members').live('click', function() { collapse_listing(this, '#member-listing'); });
	$('#collapse-datafiles').live('click', function() { collapse_listing(this, '#datafile-listing'); });
	$('#collapse-jobs').live('click', function() { collapse_listing(this, '#job-listing'); });
	$('#collapse-microposts').live('click', function() { collapse_listing(this, '#micropost-listing'); });
	$('#collapse-tasks').live('click', function() { collapse_listing(this, '#task-listing'); });

	rotate($('#collapse-members'), 0, -5, -90);
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
