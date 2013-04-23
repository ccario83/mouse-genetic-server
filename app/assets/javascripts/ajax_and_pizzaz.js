// This file contains several ajax handlers and 

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
	for(var i = 0; i < terms.length; i++) 
	{
		pair = terms[i];
		term  = pair.split('=')[0];
		value = pair.split('=')[1];
		params[term] = value;
	};
	
	/*
	base = url.split('?')[0].split('/');
	base = base.slice(3, base.length);
	for(var i = 0; i < base.length; i+=2) 
	{
		if (i+1 > base.length) { break; }
		term = base[i];
		value = base[i+1];
		if (term == 'users') { term = 'user_id'}
		if (term == 'groups'){ term = 'group_id'}
		params[term] = value;
	};*/
	
	return params;
}

function update_div(target_div, original_link, controller)
{
	controller = typeof controller !== 'undefined' ? controller : ['', target_div.replace('#','').split('-')[0]+'s','reload'].join('/');
	// Remove the controller sub-url if present (the way will_paginate generates links...)
	original_link = original_link.replace(controller,'');
	var update_url= [original_link.split('?')[0], controller].join('')
	
	// Get url parameters
	var params = {};
	if (!(typeof(original_link)==='undefined'))
	{
		params = decode_url(original_link);
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
		success: function(response) { reload_effect($(target_div), response); after_update_div(); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	return;
}
function after_update_div()
{}

function reload_effect(div, new_html)
{
	div.html(new_html);
	div.find('ol').effect("highlight", {color: '#FCF8E3'}, 1000);
	div.find('ul').effect("highlight", {color: '#FCF8E3'}, 1000);
	return;
}

function check_jobs_progress()
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

function ajax_form_submit(submit, form_container, form_url)
{
	form_container = typeof form_container !== 'undefined' ? form_container : $(submit).parent().parent();
	form_url = typeof form_url !== 'undefined' ? form_url : $(form_container).find('form').attr('action');
	//var form_div = $(form_container).find('form');
	var formData = new FormData($(form_container).find('form'));
	

	$.ajax(
	{
		//async: false,
		type:'post',
		url: form_url,
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: formData,
		dataType: 'html',
		success: function(response) { form_submit_response($(form_div), response); after_form_submit(); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	
	return false;
}
function form_submit_response(form_div, new_html)
{
	form_div.html(new_html);
}
function after_form_submit() {};