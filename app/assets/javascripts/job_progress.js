job_id = ''

function check_progress()
{
	$.ajax(
	{
		// Send the request as a get to the url /progress/job_id (routes.rb will send this to uwf#progress with :data = id
		type:"get",
		url:'/uwf/progress/' + job_id, // job_id is passed from the show and progress actions in the uwf controller
		datatype:"json", 
		success:write_progress,
		error: function(data){alert('Cannot get the log for this job!');}
	});
	
}

function write_progress(progress_log)
{
	// The .ajax() function above is suppose to parse this already, but it doesn't seem to be working, so do it here...
	// write_progress is called when the ajax query is returned as json from the server 
	// the json string becomes process_log, which we must parse back to an array here
	//progress_log = jQuery.parseJSON(progress_log);
	
	$('#progress_log_div').empty()
	for(var i=0; i<progress_log.length; i++)
	{
		$('#progress_log_div').append(progress_log[i]);
		$('#progress_log_div').append("<br/>");
	}
	return;

}


$(document).ready(function(){
	// Keep polling the server for new markers
	timerID = setInterval('check_progress()', 1500);
});

