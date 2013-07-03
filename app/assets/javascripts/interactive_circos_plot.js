// Clinton Cario
// 7/3/2013

// Called to return from full screen to the regular viewing mode
function unfull()
{
	console.log('[ICP] Exit full screen called.');
	// Return if not in full screen mode...
	if (document.fullscreen) { document.exitFullscreen(); }
	else if (document.mozFullScreen) { document.mozCancelFullScreen(); }
	else if (document.webkitIsFullScreen) { document.webkitCancelFullScreen(); }
	console.log('[ICP] Leaving full screen mode.');
	
	// Put the thumb image in the #fs div instead of the interactive circos plot
	$('#fs').html($.thumb_html);
	
	// Reset full screen variables
	$.plots.zoom_image_list = [];
	$.plots.image_found = false;
	$.isfull = false;

};

// Due to weird behavior of changefullscreen. There isn't a exitfullscreen like listener
function unfull2()
{
	console.log('[ICP] Leaving full screen mode via escape key');
	if (document.fullscreen) { return; }
	else if (document.mozFullScreen) { return;  }
	else if (document.webkitIsFullScreen) { return;  }
	$('#fs').html($.thumb_html);
	
	// Reset full screen variables
	$.plots.zoom_image_list = [];
	$.plots.image_found = false;
	$.isfull = false;

};

// Function to take the user into full screen mode
function full(el)
{
	console.log('[ICP] Entering fullscreen mode.');
	if (document.fullscreen) { return; }
	else if (document.mozFullScreen) { return; }
	else if (document.webkitIsFullScreen) { return; }
	
	// To prevent infinite calls trying to activate buttons 
	$.timer_attempts = 0;
	// Go full screen
	if(el.webkitRequestFullScreen) 
	{
		el.webkitRequestFullScreen();
	}
	else 
	{
		el.mozRequestFullScreen();
	}
	
	// Get the path of the SVG image
	var job_root_path = $('#job_root_path').text();
	image_path = job_root_path+"/circos_im.svg";
	
	// Set the current_image_tag to the full genome plot tag and reset the last_image_tag
	$.plots.current_image_tag = "-1_-1_-1";
	$.plots.last_image_tag = "";
	// Replace the PNG thumbnail with the SVG image, but keep the thumb image HTML for when we exit full screen
	$.thumb_html = $('#fs').html();
	$('#fs').html(get_circos($.plots.current_image_tag));
	
	// Attempt to shade any segments whose images have already been generated
	color_loaded_segments();
	
	// Disable the 'last' and zoom-out buttons
	//button_toggle("polygon#right", "disable");
	button_toggle("polygon#left", "disable");

	// Set the isfull state to true
	$.isfull = true;
};

// Convert an image_tag to a URL path corresponding to the image
function image_tag_to_path(image_tag)
{
	//console.log('[ICP]     getting path for image tag[' + image_tag + ']');
	var job_root_path = $('#job_root_path').text();
	// Break apart the image tag into its chromosome/positional elements
	var location = image_tag.split('_');
	var chromosome = location[0];
	var start_pos = location[1];
	var stop_pos = location[2];

	// Get the sub URL of the image, depending on plot type (full genome vs chromosomal, etc...)
	var image = ''
	if (chromosome == -1)
	{
		image = 'circos_im.svg'
	}
	else if (start_pos == -1 && stop_pos == -1)
	{
		image = 'Chr'+chromosome+'/circos_im.svg';
	}
	else
	{
		image = 'Chr'+chromosome+'/'+start_pos+'_'+stop_pos+'/circos_im.svg';
	}

	// Append the root URL and return
	image_path = job_root_path+'/'+image;
	return image_path;
};

// Query the /exists URL with an image path via AJAX to see if the image exists (ie. its done being generated)
function image_exists(image_path)
{
	//console.log('[ICP]     checking if [' + image_path + '] exists.');
	//Check that the image exists
	image_found = true;
	$.ajax(
	{
		url: '/exists'+image_path,
		async: false,
		error: function(){alert("The server isn't sure if that file exists or not!");},
		success: function(data) { image_found = data['status']; if (image_found) {/*console.log('[ICP]     Image exists.');*/} },
	});
	return image_found;
};


// Swap the current plot in the #fs element with a new image
function request_circos_image(image_tag) 
{
	console.log('[ICP] Requesting image with tag [' + image_tag + ']');
	var image_path = image_tag_to_path(image_tag);
	if (!image_exists(image_path))
	{ 
		// Don't try to generate another image if we are already working on it
		if ($.inArray(image_tag, $.plots.loading_images)!=-1) { return; }
		generate_circos_image(image_tag); 
		return;
	}

	// Store the old element for zooming out
	$.plots.zoom_image_list.push($.plots.current_image_tag);
	$.plots.last_image_tag = ""
	$.plots.current_image_tag = image_tag;
	
	// Generate the new SVG element and replace the iframe source with it
	$('#fs').html(get_circos(image_tag));

	// Color any loaded segments
	color_loaded_segments();
	
	// Disable the 'last' button, enable the zoom-out button
	//button_toggle("polygon#right", "disable");
	button_toggle("polygon#left", "enable");
};

// Ask the server to generate a new image if the simultaneous request limit has not yet been reached for this user
function generate_circos_image(image_tag)
{
	console.log('[ICP] Image being generated with tag [' + image_tag + ']');
	if ($.plots.loading_images.length == $.plots.simultaneous_request_limit)
	{
		alert("At most only " + $.plots.simultaneous_request_limit + " image can be requested at a time.");
		return;
	}

	// Pulsate the segment so the user knows its being generated
	pulsate($("#circos_img").contents().find("#"+image_tag));

	// Get the job_id so the server knows who owns the requested image
	var job_id = $('#job_id').text();
	// Send an ajax request to start generating the requested image
	$.ajax(
	{
		// Send the request as a GET to the URL: /generate/job_id?image_tag
		type:"get",
		url:"/uwf/generate/" + job_id + "?image_tag=" + image_tag,
		datatype:"json",
	});
	
	// Add this plots image tag to the loading_images list
	$.plots.loading_images.push(image_tag);
	// Set a poll to periodically check for the new image(s) if it hasn't been started yet
	if ($.plots.timerID == null)
	{ $.plots.timerID = setInterval('check_on_images()', 2000); }

};

// A function to check on the status of images being generated (using the loading_images list)
function check_on_images()
{
	console.log('[ICP] Checking for finished image(s).');
	finished_images = [];
	// If not waiting on any images, cancel the polling timer and return
	if ($.plots.loading_images.length == 0)
	{
		clearInterval($.plots.timerID);
		$.plots.timerID = null;
		return;
	}
	
	// For each loading image, get the image tag and ask the server if it is finished using image_exists()
	for (var i = 0; i < $.plots.loading_images.length; i++) 
	{
		var image_tag = $.plots.loading_images[i];
		if (image_exists(image_tag_to_path(image_tag)))
		{
			console.log('[ICP]     Image finished for tag [' + image_tag + ']');
			stop_pulsate($("#circos_img").contents().find("#"+image_tag));
			finished_images.push(image_tag);
		}
	}
	
	// Remove finished images from the loading_images list
	for (var i = 0; i < finished_images.length; i++) 
	{
		var image_tag = finished_images[i];
		$.plots.loading_images.splice($.plots.loading_images.indexOf(image_tag), 1);
	}
};

// Zoom to the next higher level 
function zoom_out()
{
	console.log('[ICP] Zooming out.');
	if ($.plots.zoom_image_list.length != 0)
	{
		// Get the old SVG element's source and remember it for the 'last' button click
		var old_tag = $('#fs iframe').attr('name');
		$.plots.last_image_tag = old_tag;
	
		// Get the higher zoom level's SVG element
		var last_tag = $.plots.zoom_image_list.pop();
		$.plots.current_image_tag = last_tag;
		
		// Generate the new SVG element and replace the iframe source with it
		$('#fs').html(get_circos(last_tag));

		// Color any loaded segments
		color_loaded_segments();
		button_toggle("polygon#left", "enable");
	}
	// Enable the left (zoom out) button only if there is still more zooming to to
	if ($.plots.zoom_image_list.length == 0) 
	{
		button_toggle("polygon#left", "disable");
	}
	else
	{
		button_toggle("polygon#left", "enable");
	}
};

// Function disabled
function zoom_back_in()
{
	console.log('[ICP] Zooming back in.');
	if ($.plots.last_image_tag != "")
	{
		$.plots.zoom_image_list.push($.plots.last_image_tag);
		$.plots.last_image_tag = "";
		zoom_out();
	}
};

// Pulsate a section to let the user know it is being worked on
function pulsate(el)
{
	$(el).animate({ opacity: 0.0 }, 800, 'linear')
		 .animate({ opacity: 1.0 }, 800, 'linear', function () {pulsate(el)});
};
// Stop the pulsating and color it as loaded
function stop_pulsate(el)
{
	$(el).stop(true, true);
	color_loaded_segments();
};


/*
function wait_on_SVG(selector)
{
	var content = $("#circos_img").contents().find(selector);
	// JIC, wait for DOM tree to fully update
	if(content.length == 0)
	{
		console.log("content not yet available for '"+selector+"'; trying again...");
		wait_on_SVG(selector);
	}
	console.log("DOM looks ready now...");
	return; 
}*/

// This function is used to color segments of the current image that have been loaded and are clickable. 
function color_loaded_segments()
{
	//wait_on_SVG("#selections");
	var content = $("#circos_img").contents().find("#sections");

	// JIC, wait for DOM tree to fully update
	if(content.length == 0)
	{
		console.log('[ICP] Attempting to color segments, but content not yet available, retry in 1s...');
		if ($.timer_attempts++ > $.timer_attempts_threshold) { return; }
		setTimeout(function(){color_loaded_segments()}, 1000);
		return;
	}
	console.log('[ICP] Attempting to color segments, content now available and is being colored.');
	
	// Get all image tag ideas in the current plot
	var IDs = [];
	content.find('path').each(function(){ IDs.push(this.id); });

	// For each image_tag ID, check if the images is ready, and color it if it is.
	for (var i = 0; i < IDs.length; i++)
	{
		var image_tag = IDs[i];
		if (image_exists(image_tag_to_path(image_tag)))
		{
			el = $("#circos_img").contents().find("#"+image_tag)
			el.attr('style','fill:#FFFF99;stroke:none;stroke-width:0px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;fill-opacity:0.2;opacity:0.2');
		}
	}
};


// Enable or disable a button
function button_toggle(selector, state)
{
	//wait_on_SVG(selector);
	var button = $("#circos_img").contents().find(selector);

	// JIC, wait for DOM tree to fully update
	if(button.length == 0)
	{
		if ($.timer_attempts++ > $.timer_attempts_threshold) { return; }
		console.log('[ICP] Attempting to ' + state + ' button [' + selector + '], but content not yet available, retry in 1s...');
		setTimeout(function(){button_toggle(selector, state)}, 1000);
		return;
	}
	console.log('[ICP] Attempting to ' + state + ' button [' + selector + '], content now available and toggling.');

	var opacity = 0;
	var fun = ""
	
	// Re-enable
	if (state=="enable")
	{
		if (selector == "polygon#right") { fun = "top.zoom_back_in()"; }
		if (selector == "polygon#left") { fun = "top.zoom_out()"; }
		opacity = 1;
	}
	else // Disable
	{
		fun = ""
		opacity = 0.5
	}
	

	// Change button state
	button.css('fill-opacity',opacity);
	button.attr('onclick', fun);
};

/*
function update_table()
{
	console.log('[ICP] Updating the circos image parameter table.');
	// Update groups AJAX
	$.ajax(
	{
		async: false,
		type:'post',
		url: '/uwf/update_image_params_table',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: $.extend(decode_url(window.location.href), {'image_tag' : $.plots.current_image_tag }),
		dataType: 'script',
		success: function(response) { },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
	});
	return;
}*/

// Get the image_tag's corresponding image SVG XML
function get_circos(image_tag)
{
	var image_path = image_tag_to_path(image_tag);
	console.log('[ICP] Asking server for image with tag [' + image_tag + ']');
	// Update groups AJAX
	return $.ajax(
	{
		async: false, 
		type:'post',
		url: '/uwf/get_circos_panel',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: $.extend(decode_url(window.location.href), {'image_tag' : image_tag, 'image_path':image_path }),
		dataType: 'html',
		success: function(response) { },
		error: function(XMLHttpRequest, textStatus, errorThrown) { ajax_error(XMLHttpRequest, textStatus, errorThrown); },
		complete: function(resonse) { },
	}).responseText;
}

// Define variables on load
$(document).ready(function () 
{
	$.plots = {}
	$.plots.zoom_image_list = [];
	$.plots.last_image_tag = "";
	$.plots.loading_images = [];
	$.plots.simultaneous_request_limit = 3;
	$.plots.timerID = null;
	// This threshold is for all timers. 
	$.timer_attempts_threshold = 50;
	$.timer_attempts = 0;
	$.isfull = false;
	$(document).on('webkitfullscreenchange mozfullscreenchange fullscreenchange', unfull2);
});
