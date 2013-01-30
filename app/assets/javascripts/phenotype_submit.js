var stats_timerID = 0;
var poll_counter = 0;


var data;

/* =============================================================================== */ 
/* =     Set all on change events on page load                                   = */
/* =============================================================================== */
$(window).bind("load", function()
{
	// Truncate the pathology list
	$('#path-list').jTruncate({  
		length: 35,
		minTrail: 0,
		moreText: "[see all]",
		lessText: "[hide extra]",
		ellipsisText: "...",
		moreAni: "fast",
		lessAni: "fast",
	});
	// Truncate the anatomy list
	$('#anat-list').jTruncate({  
		length: 35,
		minTrail: 0,
		moreText: "[see all]",
		lessText: "[hide extra]",
		ellipsisText: "...",
		moreAni: "fast",
		lessAni: "fast",
	});

	$('#please-wait').modal('show');
	poll_stats(ID);
	$('#submit-right').click(function () { $('#choice-modal').modal('show'); });
	$('#choice-submit').click(function () { post_to_url('/phenotypes/analyze', { measure: $('input:radio[name=measure]:checked').val(), mpath_id_list:JSON.stringify(MPATH_ID_LIST), anat_id_list:JSON.stringify(ANAT_ID_LIST), selected_strains:JSON.stringify(STRAINS), youngest:YOUNGEST, oldest:OLDEST, code:CODE, sex:SEX}); });

});


function update_table(strains, means, stderrs, letters)
{
	var is_header = true;
	var strain_idx = 0;
	// Create some colors for common groupings
	var colors = { 'A':'#B7F268', 'AB':'#effab4', 'B':'#ffc48c', 'ABC':'#ff9f80', 'BC':'#594f4f', 'C':'#edc951', 'D':'#031634' };
	//var fills = { 'A':'#C9E2E7', 'B':'#a7dbd8', 'C':'#e0e4cc', 'D':'#f38630', 'E':'#c02942', 'F':'#542437', 'G':'#53777a' };

	$('#stat-table tr').each(function()
	{
		if (is_header)
		{
			//$(this).find('th').eq(2).after('<th>Mean Severity Value</th><th>Severity Standard Error</th><th>Siginficance Groupings</th>');
			is_header=false;
		}
		else
		{
			$(this).find('td').eq(2).after('<td>'+means[strain_idx].toFixed(2)+'</td><td>'+stderrs[strain_idx].toFixed(3)+'</td><td style="text-shadow: -1px -1px 0 #ccc, 1px -1px 0 #ccc, -1px 1px 0 #999, 1px 1px 0 #999; color:'+colors[letters[strain_idx].toUpperCase()]+'; font-size:22px;">'+letters[strain_idx].toUpperCase()+'</td>');
			strain_idx = strain_idx+1;
		}
	});
	$('#please-wait').modal('hide');
	// Enable the tablesorter plugin
	$("#stat-table").tablesorter(); 
	// Enable the Significant grouping tooltip
	$('#sig-grouping-tooltip').tooltip();
}


/* =============================================================================== */ 
/* =     Functions to handle stats and associated ajax calls                     = */
/* =============================================================================== */

function poll_stats(id)
{
	if (stats_timerID != 0)
	{
		console.log("[" + stats_timerID + "]\t[------]\tERROR! Previous timer is STILL alive...");
		clearInterval(stats_timerID);
	}
	console.log("[" + stats_timerID + "]\t[" + id + "]\tStarting polling job for this id... ");

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
	if (poll_counter > 15)
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

		update_table(jQuery.parseJSON(response['strains']), jQuery.parseJSON(response['means']), jQuery.parseJSON(response['stderrs']), jQuery.parseJSON(response['letters']))
	}

};


/* =============================================================================== */ 
/* =     Function to post data for stat processing  (thanks stackoverflow!)      = */
/* =============================================================================== */
function post_to_url(path, params, method)
{
	method = method || "post";

	var form = document.createElement("form");
	form.setAttribute("method", method);
	form.setAttribute("action", path);

	for(var key in params)
	{
		if(params.hasOwnProperty(key))
		{
			var hiddenField = document.createElement("input");
			hiddenField.setAttribute("type", "hidden");
			hiddenField.setAttribute("name", key);
			hiddenField.setAttribute("value", params[key]);
			form.appendChild(hiddenField);
		}
	}
	
	// Set CSRF token
	var hiddenField = document.createElement("input");
	hiddenField.setAttribute("type", "hidden");
	hiddenField.setAttribute("name", "authenticity_token");
	hiddenField.setAttribute("value", $('meta[name="csrf-token"]').attr('content'));
	form.appendChild(hiddenField);
	
	document.body.appendChild(form);
	form.submit();
}
