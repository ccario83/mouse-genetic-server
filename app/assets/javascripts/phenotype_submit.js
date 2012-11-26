var data;


function update_table(grouped_by_strain)
{
	var table = new Array(), i = 0;
	table[i++] = '<tr><th>Strain</th><th>Number of Mice</th></tr>'
	for (var group_num = 0; group_num < grouped_by_strain.length; group_num++)
	{
		table[i++] ='<tr><td>';
		table[i++] = grouped_by_strain[group_num][0]['strain'];
		table[i++] = '</td><td>';
		table[i++] = grouped_by_strain[group_num].length;
		table[i++] = '</td></tr>';

	}
	$('#selected_strains').empty().append(table.join(''));
}


/* =============================================================================== */ 
/* =     Functions to handle stats and associated ajax calls                     = */
/* =============================================================================== */
function do_stats(MPATH, ANAT, STRAINS, YOUNGEST, OLDEST, CODE, SEX)
{
	stats_timerID = 0;
	poll_counter = 0;
	if (stats_timerID != 0)
	{
		console.log("[" + stats_timerID + "]\t[------]\tAttempting to clear previous timer... ");
		clearInterval(stats_timerID);
		stats_timerID = 0;
	}
	
	console.log("[" + stats_timerID + "]\t[------]\tStats are being requested... ");
	$.ajax(
	{
		// Send the request as a get to the url /generate/job_id?image_tag
		async: false,
		type:'post',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		url: '/phenotypes/stats',
		data: {mpath:MPATH, anat:ANAT, selected_strains:STRAINS, youngest:YOUNGEST, oldest:OLDEST, code:CODE, sex:SEX},
		dataType:'json',
		success: function(id) { poll_stats(id); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { clearInterval(stats_timerID); status_timerID = 0; alert("Error: " + errorThrown);},
	});
}

function poll_stats(id)
{
	if (stats_timerID != 0)
	{
		console.log("[" + stats_timerID + "]\t[------]\tERROR! Previous timer is STILL alive...");
		clearInterval(stats_timerID);
	}
	console.log("[" + stats_timerID + "]\t[" + id + "]\tServer ack sent data, send tracking id... ");

	stats_timerID = setInterval(function()
	{ 
		$.ajax(
		{
			// Send the request as a get to the url /generate/job_id?image_tag
			async: false,
			type:'post',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			url: '/phenotypes/check_stats',
			data: {id:id},
			dataType:'json',
			success: function(response) { check_stats(response); },
			error: function(XMLHttpRequest, textStatus, errorThrown) { clearInterval(stats_timerID); status_timerID = 0; alert("Error: " + errorThrown);},
		});
	}, 1000);
	console.log("[" + stats_timerID + "]\t[" + id + "]\tA new polling timer has been started...");
};


function check_stats(response)
{
	poll_counter = poll_counter + 1;
	if (poll_counter > 10)
	{
		console.log("[" + stats_timerID + "]\t[" + response['id'] + "]\tThis counter appears to be in an infinite loop; terminating ...");
		poll_counter = 0;
		clearInterval(stats_timerID);
		stats_timerID = 0;
		return;
	}
	// The server will return null if the job isn't done, otherwise it returns the letters
	if (response['status'] == 'Not ready.')
	{
		console.log("[" + stats_timerID + "]\t[" + response['id'] + "]\tChecking on stat job ... and its not ready");
		return;
	}
	else
	{
		console.log("[" + stats_timerID + "]\t[" +  response['id'] + "]\tChecking on stat job  ... READY!");
		clearInterval(stats_timerID);
		stats_timerID = 0;
		console.log("[" + stats_timerID + "]\t[" +  response['id'] + "]\tCleared stat timer ... ");
		
		groupings = jQuery.parseJSON(response['data']);
		// Create some colors for common groupings
		var colors = { 'A':'#d1f2a5', 'AB':'#effab4', 'B':'#ffc48c', 'ABC':'#ff9f80', 'BC':'#594f4f', 'C':'#edc951', 'D':'#031634' };
		//var fills = { 'A':'#C9E2E7', 'B':'#a7dbd8', 'C':'#e0e4cc', 'D':'#f38630', 'E':'#c02942', 'F':'#542437', 'G':'#53777a' };
		
		for (var i = 0; i < chart.series[0].data.length; i++)
		{
			var x = chart.plotLeft + chart.xAxis[0].translate(i, false) - 8;
			var y = chart.yAxis[0].bottom -20;
			chart_groupings['text'][i] = chart.renderer.text(groupings[i].toUpperCase(), x, y).attr(
			{
				zIndex: 100,
			}).css(
			{
				color: colors[groupings[i].toUpperCase()],
				fontSize: '18px',
				fontWeight: 'bold',
				'text-shadow': '-1px -1px 0 #ccc, 1px -1px 0 #ccc, -1px 1px 0 #999, 1px 1px 0 #999;',
			}).add();
			
			/*
			var box = chart_groupings['text'][i].getBBox();
			chart_groupings['box'][i] = chart.renderer.rect(box.x - 5, box.y - 5, box.width + 10, box.height + 10, 5).attr(
			{
				fill: fills[groupings[i].toUpperCase()],
				stroke: '#fff',
				'stroke-width': 1,
				zIndex: 4,
			}).add();
			*/
		}
	}

};
