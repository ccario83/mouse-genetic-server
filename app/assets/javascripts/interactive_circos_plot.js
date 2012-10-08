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

function request_circos_image(image_tag) 
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
	
	image = "/data/"+job_ID+"/Plots/"+image;
	
	
	//Check that the image exists
	$.plots.image_found = true;
	$.ajax(
	{
		url:image,
		type:'HEAD',
		async: false,
		error: function(x, e)
		{
			if (x.status == 500 || x.status == 404)
			{
				$.plots.image_found = false;
			}
		},
	});
	if (!$.plots.image_found)
	{ 
		alert("This image isn't ready yet");
		return; 
	}
		
	var parent = $('iframe#circos_img').parent();
	var newElement = "<iframe id='circos_img' src='"+image+"' type='image/svg+xml' style='border: 0px;'></iframe>";
	
	var oldElement = $('iframe#circos_img').attr('src');
	$.plots.zoom_image_list.push(oldElement);

	$('iframe#circos_img').remove();
	parent.append(newElement);

};


function zoom_out()
{

	var lastImage = $.plots.zoom_image_list.pop();
	var parent = $('iframe#circos_img').parent();
	var newElement = "<iframe id='circos_img' src='"+lastImage+"' type='image/svg+xml' style='border: 0px;'></iframe>";
	$('iframe#circos_img').remove();
	parent.append(newElement);
};

$(document).ready(function () 
{
	$.plots = {}
	$.plots.zoom_image_list = [];
	$.plots.image_found = false;
	
	$(document).on('webkitfullscreenchange mozfullscreenchange fullscreenchange', unfull);

});
