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
		image = 'circos.svg'
	}
	else if (start_pos == -1 && stop_pos == -1)
	{
		image = 'Chr'+chromosome+'/circos.svg';
	}
	else
	{
		image = 'Chr'+chromosome+'/'+start_pos+'_'+stop_pos+'circos.svg';
	}
	
	image = "/data/"+job_ID+"/Plots/"+image;
	
	var parent = $('iframe#circos_img').parent();
	var newElement = "<iframe id='circos_img' src='"+image+"' type='image/svg+xml' style='border: 0px;'></iframe>";

	$('iframe#circos_img').remove();
	parent.append(newElement);

};
