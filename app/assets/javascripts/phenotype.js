// Variables that change with queries and are repopulated with ajax
var SELECTED_STRAINS = all_strains;
var YOUNGEST = very_youngest;
var OLDEST = very_oldest;
var CODE = '';
var SEX = 'B';

var stats_timerID = 0;
var chart;
var groupings;

var chart_groupings = [];
chart_groupings['box'] = [];
chart_groupings['text'] = [];

// Global for debugging purposes
var data;
var grouped_by_strain;
var severities;
var poll_counter = 0;


$(window).bind("load", function()
{
	lookup();
	$("#M_mouse").click(function() { change_sex_selection('M'); });
	$("#F_mouse").click(function() { change_sex_selection('F'); });
	// The age_range onClick is set by set_age_slider() on the initial lookup call; it doesn't work when it is set here
	$("#code").change(function() { change_code(); });
});

function lookup()
{
	// Clear the timer and set the id to zero (prevents infinite polling)
	clearInterval(stats_timerID);
	stats_timerID = 0;
	console.log("[---]\t[------]\tRequesting new filtered strain data...");
	//alert('mpath: ' + mpath  + ' anat: ' + anat + ' youngest: ' + youngest + ' oldest: ' + OLDEST + ' sex: ' + SEX); 
	//var url = "/phenotypes/query?MPATH=" + mpath + "&MA=" + anat + "&youngest=" + youngest + "&oldest=" + OLDEST + "&sex=" + SEX + "&SELECTED_STRAINS=" + encodeURIComponent(SELECTED_STRAINS);
	//
	$.ajax(
	{
		// Send the request as a get to the url /generate/job_id?image_tag
		//async: false,
		type:'post',
		url: '/phenotypes/query',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: {MPATH:mpath, MA:anat, youngest:YOUNGEST, oldest:OLDEST, code:CODE, sex:SEX, selected_strains:SELECTED_STRAINS},
		dataType:'json',
		success: function(data) { process_data(data); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Status: " + textStatus); alert("Error: " + errorThrown);},
	});
}

function process_data(data_)
{
	// set the data globally
	data = data_;
	grouped_by_strain = _.toArray(_.groupBy(data, function(item){ return _.indexOf(SELECTED_STRAINS, item['strain']); }))
	SELECTED_STRAINS = _.uniq(_.pluck(data,'strain'));
	selected_sexes = get_sexes(grouped_by_strain);

	set_age_slider(get_age_range(grouped_by_strain));
	set_sex_selection(selected_sexes);
	
	//update_table(grouped_by_strain);


	var frequencies = new Array();
	severities = new Array();
	for (idx in data)
	{
		var sex = data[idx].sex;
		var strain = data[idx].strain;
		var score = data[idx].score;
		
		if (typeof(severities[sex]) === "undefined")
		{
			severities[sex] = new Array();
			frequencies[sex] = new Array();
		}
		if (typeof(severities[sex][strain]) === "undefined")
		{
			severities[sex][strain] = new Array();
			frequencies[sex][strain] = new Array();
			frequencies[sex][strain]['freq'] = 0;
			frequencies[sex][strain]['total'] = 0;
		}
		severities[sex][strain].push(score);
		if (score > 0)
			frequencies[sex][strain]['freq']++;
		frequencies[sex][strain]['total']++;
	}
	
	var average_severities = new Array();
	for (var sex in severities)
	{
		for (strain in severities[sex])
		{
			if (typeof(average_severities[sex]) === "undefined")
				{ average_severities[sex] = new Array(); }
			var sum = _.reduce(severities[sex][strain], function(a, b){ return a + b; }, 0);
			average_severities[sex][strain] = (sum / severities[sex][strain].length).toFixed(2);
			//console.log(average_severities[sex][strain]);
		}
	}

	update_bar_chart(SELECTED_STRAINS, selected_sexes, average_severities, frequencies);

}



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



function set_age_slider(age_range)
{
	var YOUNGEST = age_range[0];
	var OLDEST = age_range[1];
	// Now set during initial page load
	//very_youngest = (typeof(very_youngest) === "undefined") ? YOUNGEST : very_youngest;
	//very_oldest = (typeof(very_oldest) === "undefined") ? OLDEST : very_oldest;
	$("#age-range").slider(
	{
		range: true,
		min: very_youngest,
		max: very_oldest,
		values: [ YOUNGEST, OLDEST ],
		slide: function( event, ui )
		{
			$( "#ages" ).val(ui.values[ 0 ] + " - " + ui.values[ 1 ] );
		}, 
	});
	$( "#ages" ).val($( "#age-range" ).slider( "values", 0 ) + " - " + $( "#age-range" ).slider( "values", 1 ) );
	// Set the stop function here cause it doesn't like it in document.ready()
	$("#age-range").slider("option", "stop", function() { change_age_slider() } );
}



function get_age_range(grouped_by_strain)
{
	YOUNGEST = _.min(_.map(_.flatten(grouped_by_strain), function(item){ return item.age; }));
	OLDEST = _.max(_.map(_.flatten(grouped_by_strain), function(item){ return item.age; }));
	return [YOUNGEST, OLDEST];
}



function change_age_slider()
{
	CODE = '';
	SEX = 'B';
	YOUNGEST = $("#age-range").slider("option","values")[0];
	OLDEST = $("#age-range").slider("option","values")[1];
	lookup();
}

function change_code()
{
	SEX = 'B';
	YOUNGEST = very_youngest;
	OLDEST = very_oldest;
	CODE = $('#code').val();
	lookup();
}

function set_sex_selection(sexes)
{
	$("#M_mouse").addClass('unselected');
	$("#F_mouse").addClass('unselected');
	if (sexes == 'B')
	{
		$("#M_mouse").removeClass('unselected');
		$("#F_mouse").removeClass('unselected');
	}
	else { $("#"+sexes+"_mouse").removeClass('unselected'); }
}



function get_sexes(grouped_by_strain)
{
	var sexes = _.uniq(_.map(_.flatten(grouped_by_strain), function(item){ return item.sex; }))
	if (sexes.length>1)
	{return "B";}
	else
	{return sexes;}
}



function change_sex_selection(clicked_sex)
{
	
	
	if (!$("#M_mouse").hasClass('unselected') && (!$("#F_mouse").hasClass('unselected')))
	{
		$("#"+clicked_sex+"_mouse").addClass('unselected');
		if (clicked_sex == 'M'){ SEX = 'F' }
		else {SEX = 'M'}
	}
	else if (((!$("#M_mouse").hasClass('unselected')) && $("#F_mouse").hasClass('unselected') && clicked_sex == 'F') || ((!$("#F_mouse").hasClass('unselected')) && $("#M_mouse").hasClass('unselected') && clicked_sex == 'M'))
	{
		$("#"+clicked_sex+"_mouse").removeClass('unselected');
		SEX = 'B'
	}
	else
	{
		if (clicked_sex == 'M'){ SEX = 'F' }
		else {SEX = 'M'}

		$("#"+clicked_sex+"_mouse").addClass('unselected');
		$("#"+SEX+"_mouse").removeClass('unselected');
	}
	
	lookup();
}



function update_bar_chart(SELECTED_STRAINS, selected_sexes, average_severities, frequencies)
{

	SELECTED_STRAINS = SELECTED_STRAINS.sort();
	charted_data = [];
	
	// Generate the data
	if (selected_sexes == 'B' || selected_sexes == 'M')
	{
		var freq_m = _.map(SELECTED_STRAINS, function(strain)
		{
			// Get the value if defined
			var value = 0;
			if (typeof(frequencies['M'])==="undefined")
				{ return 0; }
			else
				{ if (typeof(frequencies['M'][strain])==="undefined") { return 0; } }
			var value = frequencies['M'][strain];
		
			// Compute the percentage, if able
			return (value['total']==0) ? 0 : parseFloat((value['freq']/value['total']).toFixed(2));
		});
		charted_data.push(
		{
			name: 'Frequency M',
			color: '#7ebacf',
			data: freq_m,
			yAxis: 0,
		});
	
		var sev_m = _.map(SELECTED_STRAINS, function(strain)
		{
			// Get the value if defined
			var value = 0;
			if (typeof(average_severities['M'])==="undefined")
				{ return 0; }
			else
				{ if (typeof(average_severities['M'][strain])==="undefined") { return 0; } }
			var value = average_severities['M'][strain];
		
			// Compute the percentage, if able
			return (typeof(value)==="undefined") ? 0 : parseFloat(value);
		});
		charted_data.push(
		{
			name: 'Severity M',
			color: '#C7E9F5',
			data: sev_m,
			yAxis: 1,
		});
	}
	
	
	if (selected_sexes == 'B' || selected_sexes == 'F')
	{
		var freq_f = _.map(SELECTED_STRAINS, function(strain)
		{
			// Get the value if defined
			var value = 0;
			if (typeof(frequencies['F'])==="undefined")
				{ return 0; }
			else
				{ if (typeof(frequencies['F'][strain])==="undefined") { return 0; } }
			var value = frequencies['F'][strain];
		
			// Compute the percentage, if able
			return (value['total']==0) ? 0 : parseFloat((value['freq']/value['total']).toFixed(2));
		});
		charted_data.push(
		{
			name: 'Frequency F',
			color: '#d483a8',
			data: freq_f,
			yAxis: 0,
		});

		var sev_f = _.map(SELECTED_STRAINS, function(strain)
		{
			// Get the value if defined
			var value = 0;
			if (typeof(average_severities['F'])==="undefined")
				{ return 0; }
			else
				{ if (typeof(average_severities['F'][strain])==="undefined") { return 0; } }
			var value = average_severities['F'][strain];
		
			// Compute the percentage, if able
			return (typeof(value)==="undefined") ? 0 : parseFloat(value);
		});
		charted_data.push(
		{
			name: 'Severity F',
			color: '#FBCFE3',
			data: sev_f,
			yAxis: 1,
		});
	}
	
	
	// Create the chart
	chart = new Highcharts.Chart(
	{
		chart:
		{
			renderTo: 'chart',
			type: 'column'
		},
		title: { text: 'Strain Response' },
		subtitle: { text: '' },
		xAxis:
		{
			categories: SELECTED_STRAINS,
			labels: 
			{
				rotation: 90,
				align: "left",	
			},
		},
		yAxis:
		[
			{  // Frequency yAxis
				min: 0,
				title: { text: 'Frequency' },
			},
			{  // Severity yAxis
				min: 0,
				title: { text: 'Severity' },
				opposite: true,
			},
		],
		legend:
		{
			layout: 'vertical',
			backgroundColor: '#FFFFFF',
			align: 'right',
			verticalAlign: 'middle',
			x: 0,
			y: 0,
			floating: false,
			shadow: true
		},
		tooltip:
		{
			formatter: function() { return ''+ this.x +': '+ this.y; }
		},
		plotOptions:
		{
			column:
			{
				pointPadding: 0.2,
				borderWidth: 0, 
				events:
				{
					legendItemClick: function() {setTimeout(adjust_groupings,1500);},
				}
			}
		},
		series: charted_data,
		events:
		{
			load: do_stats(),
		}
	});
};


function do_stats()
{
	stats_timerID = 0;
	poll_counter = 0;
	if (stats_timerID != 0)
	{
		console.log("[" + stats_timerID + "]\t[------]\tAttempting to clear previous timer... ");
		clearInterval(stats_timerID);
		stats_timerID = 0;
	}
	console.log("[" + stats_timerID + "]\t[------]\tTukeys HSD groups are being requested... ");
	var strains = [];
	var values = [];
	
	for (var sex in severities)
	{
		severity = severities[sex]
		for (str in severity)
		{
			if (severity.hasOwnProperty(str))
			{
				for (val in severity[str])
				{
					//console.log(sex +": "+str +": "+severity[str][val]);
					strains.push(str);
					values.push(severity[str][val]);
				}
			}
		}
	}
	
	//alert('mpath: ' + mpath  + ' anat: ' + anat + ' youngest: ' + YOUNGEST + ' oldest: ' + OLDEST + ' sex: ' + SEX); 
	//var url = "/phenotypes/stats?values=" + encodeURIComponent(values) + "&strains=" + encodeURIComponent(strains);
	//
	console.log("[" + stats_timerID + "]\t[------]\tSending strain data to server via AJAX post...");
	$.ajax(
	{
		// Send the request as a get to the url /generate/job_id?image_tag
		async: false,
		type:'post',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		url: '/phenotypes/stats',
		data: {strains:strains, values:values},
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
	if (poll_counter > 5)
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
		var colors = { 'A':'#69d2e7', 'B':'#a7dbd8', 'C':'#e0e4cc', 'D':'#f38630', 'E':'#c02942', 'F':'#542437', 'G':'#53777a' };
		//var fills = { 'A':'#C9E2E7', 'B':'#a7dbd8', 'C':'#e0e4cc', 'D':'#f38630', 'E':'#c02942', 'F':'#542437', 'G':'#53777a' };
		
		for (var i = 0; i < chart.series[0].data.length; i++)
		{
			var x = chart.plotLeft + chart.xAxis[0].translate(i, false) -5;
			var y = chart.yAxis[0].bottom -20;
			chart_groupings['text'][i] = chart.renderer.text(groupings[i].toUpperCase(), x, y).attr(
			{
				zIndex: 100,
			}).css(
			{
				color: colors[groupings[i].toUpperCase()],
				fontSize: '18px',
				//'text-shadow': '2px 2px 2px rgba(150, 150, 150, 1);',
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


function adjust_groupings()
{
	if (typeof(chart) === "undefined" || typeof(groupings) === "undefined")
			{ return; }

	console.log("redrawing groupings");
	for (var i = 0; i < chart.series[0].data.length; i++)
	{
		var x = chart.plotLeft + chart.xAxis[0].translate(i, false) -5;
		var y = chart.yAxis[0].bottom -20;

		chart_groupings['text'][i].attr({ x: x, y: y});
		//var box = chart_groupings['text'][i].getBBox();
		//chart_groupings['box'][i].attr({ x: box.x - 5, y: box.y - 5});
	}
};
