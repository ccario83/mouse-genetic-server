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
		error: function(){clearInterval(timerID); location.reload();}
	});
	
}

function write_progress(progress_log)
{
	// The .ajax() function above is suppose to parse this already, but it doesn't seem to be working, so do it here...
	// write_progress is called when the ajax query is returned as json from the server 
	// the json string becomes process_log, which we must parse back to an array here
	//progress_log = jQuery.parseJSON(progress_log);
	if (progress_log == "finished") { location.reload(); }
	for(var i=0; i<progress_log.length; i++)
	{
		$('#'+progress_log[i]).removeClass('incomplete').addClass('complete');
	}
	return;

}


$(document).ready(function(){
	check_progress();
	// Keep polling the server for new markers
	timerID = setInterval('check_progress()', 5000);
});

