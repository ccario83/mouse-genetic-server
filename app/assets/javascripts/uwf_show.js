var uwf_timer_id;

function check_progress()
{
	$.ajax(
	{
		// Send the request as a get to the url /progress/job_id (routes.rb will send this to uwf#progress with :data = id
		type:'get',
		url: '/uwf/progress/' + parseInt($('#job_id').html()), // job_id embedded as a hidden span
		datatype: 'json', 
		success: write_progress,
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert('Error: ' + errorThrown);},
	});
	
}

function write_progress(response)
{
	// The .ajax() function above is suppose to parse this already, but it doesn't seem to be working, so do it here...
	// write_progress is called when the ajax query is returned as json from the server 
	// the json string becomes process_log, which we must parse back to an array here
	//progress_log = jQuery.parseJSON(progress_log);
	var progress_log = response['log'];
	var errors = response['errors'];
	
	for(var i=0; i<progress_log.length; i++)
	{
		$('#'+progress_log[i]).removeClass('incomplete').addClass('complete');
	}
	if (errors.length>0)
	{
		$('#job-progress .incomplete').first().removeClass('incomplete').addClass('error');
		clearInterval(uwf_timer_id);
	}
	
	
	
	if (progress_log.indexOf('completed') >= 0) 
	{
		clearInterval(uwf_timer_id);
		document.location.reload();
	}
	
	return;
}


$(document).ready(function(){
	check_progress();
	// Keep polling the server for new markers
	uwf_timer_id = setInterval('check_progress()', 5000);
});

