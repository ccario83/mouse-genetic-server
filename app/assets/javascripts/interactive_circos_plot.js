function unfull()
{
	// Only do this if we are in full screen mode...
	if (document.fullscreen) { return; }
	if (document.mozFullScreen) { return; }
	if (document.webkitIsFullScreen) { return; }
	
	var job_ID = $('#job_ID').text();
	image = "/data/"+job_ID+"/Plots/circos.png";
	var newElement = "<img alt='Circos' id='circos_thumb' src="+image+" width='75%' />"

	var parent = document.getElementById('fs');
	parent.innerHTML = newElement;
	
	$.plots.zoom_image_list = [];
	$.plots.image_found = false;

};

function full(el)
{

	// Go fullscreen
	if(el.webkitRequestFullScreen) 
	{
		el.webkitRequestFullScreen();
	}
	else 
	{
		el.mozRequestFullScreen();
	}
	
	// Get the path of the SVG image
	var job_ID = $('#job_ID').text();
	image_path = "/data/"+job_ID+"/Plots/circos_im.svg";
	
	
	// Replace the PNG thumbnail with the SVG image
	var newElement = "<iframe id='circos_img' src='"+image_path+"' type='image/svg+xml' style='border: 0px;'></iframe>";
	document.getElementById('fs').innerHTML = newElement;

	// Color any loaded segments
	color_loaded_segments();

	// Disable the 'last' and zoom-out buttons
	$.plots.last_image_tag = ""
	button_toggle("polygon#right", "disable");
	button_toggle("polygon#left", "disable");
};


function image_tag_to_path(image_tag)
{
	var job_ID = $('#job_ID').text();
	var location = image_tag.split('_');
	var chromosome = location[0];
	var start_pos = location[1];
	var stop_pos = location[2];

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

	image_path = "/data/"+job_ID+"/Plots/"+image;
	return image_path;
};


function image_exists(image_path)
{
	//Check that the image exists
	image_found = true;
	$.ajax(
	{
		url: '/exists/'+image_path,
		async: false,
		error: function(){alert("The server isn't sure if that file exists or not!");},
		success: function(data) { image_found = data['status'] },
	});
	return image_found;
};


function request_circos_image(image_tag) 
{
	var image_path = image_tag_to_path(image_tag);
	if (!image_exists(image_path))
	{ 
		// Don't try to generate another image if we are already working on it
		if ($.inArray(image_tag, $.plots.loading_images)!=-1) { return; }
		generate_circos_image(image_tag); 
		return;
	}

	// Store the old element for zooming out
	var oldElement = $('iframe#circos_img').attr('src');
	$.plots.zoom_image_list.push(oldElement);
	
	// Generate the new SVG element and replace the iframe source with it
	var newElement = "<iframe id='circos_img' src='"+image_path+"' type='image/svg+xml' style='border: 0px;'></iframe>";
	document.getElementById('fs').innerHTML = newElement;

	// Color any loaded segments
	color_loaded_segments();
	
	// Disable the 'last' button, enable the zoom-out button
	$.plots.last_image_tag = ""
	button_toggle("polygon#right", "disable");
	button_toggle("polygon#left", "enable");
};


function generate_circos_image(image_tag)
{

	if ($.plots.loading_images.length == $.plots.simultaneous_request_limit)
	{
		alert("Please, only " + $.plots.simultaneous_request_limit + " image request at a time!");
		return;
	}

	var job_ID = $('#job_ID').text();
	pulsate($("#circos_img").contents().find("#"+image_tag));
	
	// Send an ajax request to start generating the requested image
	$.ajax(
	{
		// Send the request as a get to the url /generate/job_id?image_tag
		type:"get",
		url:"/uwf/generate/" + job_ID + "?image_tag=" + image_tag,
		datatype:"json",
	});
	
	$.plots.loading_images.push(image_tag);
	// Periodically poll for the new images
	$.plots.timerID = setInterval('check_on_images()', 1000);

};


function check_on_images()
{
	finished_images = [];
	if ($.plots.loading_images.length == 0)
	{
		clearInterval($.plots.timerID)
		return;
	}
	
	for (var i = 0; i < $.plots.loading_images.length; i++) 
	{
		var image_tag = $.plots.loading_images[i];
		if (image_exists(image_tag_to_path(image_tag)))
		{
			stop_pulsate($("#circos_img").contents().find("#"+image_tag));
			finished_images.push(image_tag);
		}
	}
	
	// Remove finished images from the loading_images list
	for (var i = 0; i < finished_images.length; i++) 
	{
		$.plots.loading_images.splice($.plots.loading_images.indexOf(image_tag), 1);
	}
};


function zoom_out()
{
	if ($.plots.zoom_image_list.length != 0)
	{
		// Get the old SVG elements source and remember it for the 'last' button click
		var oldElement = $('iframe#circos_img').attr('src');
		$.plots.last_image_tag = oldElement;
	
		// Get the higher zoom level's SVG element
		var lastImage = $.plots.zoom_image_list.pop();

		// Generate the new SVG element and replace the iframe source with it
		var newElement = "<iframe id='circos_img' src='"+lastImage+"' type='image/svg+xml' style='border: 0px;'></iframe>";
		document.getElementById('fs').innerHTML = newElement;

		// Color any loaded segments
		color_loaded_segments();
	}
	if ($.plots.zoom_image_list.length == 0) 
	{ 
		button_toggle("polygon#left", "disable");
	}
	else
	{
		button_toggle("polygon#left", "enable");
	}
};

function zoom_back_in()
{
	if ($.plots.last_image_tag != "")
	{
		$.plots.zoom_image_list.push($.plots.last_image_tag);
		$.plots.last_image_tag = "";
		zoom_out();
	}
};


function pulsate(el)
{
	$(el).animate({ opacity: 0.0 }, 800, 'linear')
		 .animate({ opacity: 1.0 }, 800, 'linear', function () {pulsate(el)});
};

function stop_pulsate(el)
{
	$(el).stop(true, true);
	color_loaded_segments();
};


/*
function wait_on_SVG(selector)
{
	var content = $("#circos_img").contents().find(selector);
	// JIK, wait for DOM tree to fully update
	if(content.length == 0)
	{
		console.log("content not yet available for '"+selector+"'; trying again...");
		wait_on_SVG(selector);
	}
	console.log("DOM looks ready now...");
	return; 
}*/

function color_loaded_segments()
{
	//wait_on_SVG("#selections");
	var content = $("#circos_img").contents().find("#sections");

	// JIK, wait for DOM tree to fully update
	if(content.length == 0)
	{
		console.log("content not yet available to color sections; trying again...");
		setTimeout(function(){color_loaded_segments()}, 100);
		return;
	}
	console.log("DOM looks ready now...");
	
	var IDs = [];
	content.find('path').each(function(){ IDs.push(this.id); });

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


function button_toggle(selector, state)
{
	//wait_on_SVG(selector);
	var button = $("#circos_img").contents().find(selector);

	// JIK, wait for DOM tree to fully update
	if(button.length == 0)
	{
		console.log("content not yet available to toggle buttons; trying again...");
		return setTimeout(function(){button_toggle(selector, state)}, 100);
	}
	console.log("DOM looks ready now...");

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


$(document).ready(function () 
{
	$.plots = {}
	$.plots.zoom_image_list = [];
	$.plots.last_image_tag = "";
	$.plots.loading_images = [];
	$.plots.simultaneous_request_limit = 2;
	$.plots.timerID;
	$(document).on('webkitfullscreenchange mozfullscreenchange fullscreenchange', unfull);

});


