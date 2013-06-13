$(window).bind("load", function()
{

	// Pulsate anything with the pulsate class, but stop if it is clicked on
	(function pulse(){
		$('.pulsate').delay(200).fadeTo('slow', 0.15).delay(50).fadeTo('slow', 1, pulse);
	})();
	$('.pulsate').live('click', function() { $(this).removeClass('pulsate')  });
	
});


// This will take an arrow element (collapse-*) and the corresponding div to collapse
function collapse_listing(arrow, div)
{
	if (getRotationDegrees($(arrow))==-90) { rotate(arrow, -90, 5, 0); } else { rotate(arrow, 0, -5, -90); }
	
	if ($(div).is(":hidden"))
	{
		$(div).slideDown();
	} else {
		$(div).slideUp();
	}
}

// Function to rotate the arrow div from cur_deg to final_deg by step degrees
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

// A function to parse url encoded parameters into POST data. Returns 'params' as an associative array mapping variable to value 
function decode_url(url)
{
	// The disabled pagination 'previous' and 'next' still have active links ending with #. Ignore them
	if (url[url.length-1]=='#') { return null; }
	// url = url.replace('#','');
	params = {};
	try
	{
		terms = url.split('?')[1].split('&');
		for(var i = 0; i < terms.length; i++) 
		{
			pair = terms[i];
			term  = pair.split('=')[0];
			value = pair.split('=')[1];
			params[term] = value;
		};
	}
	catch(err) { }
	
	return params;
}

// update_div is the javascript hook that reloads the user/group panels 
// It takes the target_div (usually *-panel), the paginate link, the responding controller, whether to expand the div on return,
//  and if the call should be asyncronous. The target div is the only required parameter. The others can be determined based on context
function update_div(target_div, original_link, controller, expand, async)
{
	// Find defaults if needed
	//-------------------------
	// orginal_link is the URL a will_paginate button would request. We need this to get the pagination page number
	if (typeof original_link === 'undefined')
	{
		// If we have a pagination link (a href), get its href value, otherwise use the window path
		if (typeof($(target_div).find('div.pagination li.active a')[0]) !== 'undefined')
		{
			original_link = $(target_div).find('div.pagination li.active a')[0].href;
		} else { original_link = window.location.pathname; }
	}
	// Get the panel name, which should be the first part of the target div, like job-panel => job
	// Risky if page is not structured correctly, but user should know to pass the argument explicitly if it isn't
	var panel_name = target_div.replace('#','').split('-')[0];
	
	// Attempt to determine the URL that maps to the controller that will handle the AJAX call
	// It should be '(plural form of panel_name)/reload', like job => jobs/reload
	controller = typeof controller !== 'undefined' ? controller : ['', panel_name+'s','reload'].join('/');
	// Remove the controller sub-url if present (remove will_paginate's page parameters from the URL...)
	original_link = original_link.replace(controller,'');
	var update_url= [original_link.split('?')[0], controller].join('')
	
	// Passes an expand option to the controller
	// This is done so the state of the panel is kept between AJAX calls or so the panel can be explicitly expanded
	// Send the expand state, or use the current state
	expand = typeof expand !== 'undefined' ? expand : $(target_div).is(":visible");

	// Use the value of async if provided or use 'true'
	async = typeof async !== 'undefined' ? true : false;
	//async = typeof async !== 'undefined' ? async : false;
	//-------------------------
	
	// Get url parameters from original link if it exists (ie.. those provided in the will_paginate URL links)
	var params = {};
	if (!(typeof(original_link)==='undefined'))
	{
		params = decode_url(original_link);
		// Dont try to post bad params
		if (params == null) { return false; }
	}
	// Add the expand parameter
	params['expand'] = expand
	
	// Update using AJAX
	$.ajax(
	{
		async: async,
		type:'post',
		url: update_url,
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: params,
		dataType: 'script',
		success: function(response) { reload_effect($(target_div), response); after_update_div(); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	return;
}
// A function to call after the ajax call
function after_update_div()
{}

// Function to apply an effect to the newly loaded div. 'new_html' is depreciated
function reload_effect(div, new_html)
{
	//div.html(new_html); DEPRECIATED, ajax is call type is now 'script' instead of html, rendering the actions .js.erb file which handles html replacement
	div.find('ol').effect("highlight", {color: '#FCF8E3'}, 1000);
	div.find('ul').effect("highlight", {color: '#FCF8E3'}, 1000);
	return;
}

// An ajax call to update the job progress bars
function check_jobs_progress()
{
	// Get the job ids
	var job_ids = []
	$('.jobs li .bar').each(function() { job_ids.push(parseInt(this.id)) });
	
	// Make the AJAX call
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

// The function that actually handles job progress bar updates
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


/*
// Used by the datafile form to submit the form via AJAX
// Takes the form container and submit url and submits via AJAX instead of GET/POST
// NOTE: This function and the success function 'form_submit_response' may be replacable with the more generic attach_submit() function
function ajax_form_submit(form_container, form_url)
{
	// Get the url from the form action if not defined
	form_url = typeof form_url !== 'undefined' ? form_url : $(form_container).find('form').attr('action');
	// Get the form data
	var formData = new FormData($(form_container).find('form')[0]);
	
	// Submit to the form url 
	$.ajax(
	{
		type:'post',
		url: form_url,
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: formData,
		dataType: 'html',
		cache: false,
		contentType: false,
		processData: false,
		success: function(response) { form_submit_response($(form_container), response); after_form_submit(); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	
	return false;
}
// Responds to a successful ajax form submit
function form_submit_response(form_div, new_html, div_to_update)
{
	// The div_to_update will default to the form_div id stripped of 'new-*' with '-panel' postpented eg. "new-datatfile" => "#datafile-panel" 
	div_to_update = typeof div_to_update !== 'undefined' ? div_to_update : '#' + $(form_div)[0].id.split('-')[1] + '-panel'
	// Update the panel with the new html
	form_div.html(new_html);
	
	// Hide the modal
	$(form_div).modal('hide');
	update_div(div_to_update);
}
function after_form_submit() {};
*/

// Attach the submit button to an AJAX submit, overriding the default POST/GET action
function attach_submit(div)
{
	// Add the jQuery id '#' to the tag if necessary
	if (div[0] != '#') { div = '#'+div; }
	$(div+' input:submit').on('click', function()
	{
		var formData = new FormData($(div+' form')[0]);
		$.ajax({
			type: 'post',
			url: $(div+' form').attr('action'), //sumbits it to the given url of the form
			data: formData,
			dataType: 'script', // The corresponding view js script will update anything necessary
			cache: false,
			contentType: false,
			processData: false
		});
		return false;
	});
}
