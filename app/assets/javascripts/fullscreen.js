function full(el) 
{
	if(el.webkitRequestFullScreen) 
	{
		var job_ID = $('#job_ID').text();
		image = "/data/"+job_ID+"/Plots/circos.svg";
		var newElement = "<iframe id='circos_img' src='"+image+"' type='image/svg+xml' style='border: 0px;'></iframe>";
		
		var parent = $('#circos_thumb').parent();
		$('#circos_thumb').remove();
		parent.append(newElement);

		el.webkitRequestFullScreen();
	}
	else 
	{
		el.mozRequestFullScreen();
	}
};


