function unfull()
{
	// Only do this if we are in full screen mode...
	if (document.fullscreen) { return; }
	if (document.mozFullScreen) { return; }
	if (document.webkitIsFullScreen) { return; }
	
	var job_ID = $('#job_ID').text();
	image = "/data/"+job_ID+"/Plots/circos.png";
	var newElement = "<img alt='Circos' id='circos_thumb' src="+image+" width='75%' />"
	
	var parent = $('#circos_img').parent();
	$('#circos_img').remove();
	parent.append(newElement);
	
	$.plots.zoom_image_list = [];
	$.plots.image_found = false;

};

function full(el)
{
	var job_ID = $('#job_ID').text();
	image = "/data/"+job_ID+"/Plots/circos_im.svg";
	var newElement = "<iframe id='circos_img' src='"+image+"' type='image/svg+xml' style='border: 0px;'></iframe>";
	
	var parent = $('#circos_thumb').parent();
	$('#circos_thumb').remove();
	parent.append(newElement);
	
	if(el.webkitRequestFullScreen) 
	{
		el.webkitRequestFullScreen();
	}
	else 
	{
		el.mozRequestFullScreen();
	}

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
		url: image_path,
		type:'HEAD',
		async: false,
		error: function(x, e)
		{
			if (x.status == 404)
			{
				image_found = false;
			}
		},
	});
	return image_found;
};


function request_circos_image(image_tag) 
{

	image_path = image_tag_to_path(image_tag);
	if (!image_exists(image_path))
	{ 
		// Don't try to generate another image if we are already working on it
		if ($.inArray(image_tag, $.plots.loading_images)!=-1) { return; }
		generate_circos_image(image_tag); 
		return;
	}

	var parent = $('iframe#circos_img').parent();
	var newElement = "<iframe id='circos_img' src='"+image_path+"' type='image/svg+xml' style='border: 0px;'></iframe>";
	
	var oldElement = $('iframe#circos_img').attr('src');
	$.plots.zoom_image_list.push(oldElement);

	$('iframe#circos_img').remove();
	parent.append(newElement);

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
		image_tag = $.plots.loading_images[i];
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

	var lastImage = $.plots.zoom_image_list.pop();
	var parent = $('iframe#circos_img').parent();
	var newElement = "<iframe id='circos_img' src='"+lastImage+"' type='image/svg+xml' style='border: 0px;'></iframe>";
	$('iframe#circos_img').remove();
	parent.append(newElement);
};


function pulsate(el)
{
	$(el).animate({ opacity: 0.2 }, 1200, 'linear')
		 .animate({ opacity: 0.9 }, 1200, 'linear', function () {pulsate(el)});
};

function stop_pulsate(el)
{
	$(el).animate({ opacity: 0.9 }, 1200, 'linear').stop();
	$(el).attr('style','fill:#FFFF99;stroke:none;stroke-width:0px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;fill-opacity:1.0;opacity:0.2');
	color_loaded_segments();
};

function color_loaded_segments()
{

};


$(document).ready(function () 
{
	$.plots = {}
	$.plots.zoom_image_list = [];
	$.plots.loading_images = [];
	$.plots.simultaneous_request_limit = 1;
	$.plots.timerID;
	$(document).on('webkitfullscreenchange mozfullscreenchange fullscreenchange', unfull);

});


