// Variables that change with queries and are repopulated with ajax
var selected_strains = all_strains;
var youngest = very_youngest;
var oldest = very_oldest;
var sex = 'B';

var stats_timerID=0;
var chart;
var groupings;
var chart_groupings = [];
// Global for debugging purposes
var data;
var grouped_by_strain;
var severities;


$(window).bind("load", function()
{
	lookup(mpath, anat, youngest, oldest, sex, selected_strains);
	$("#M_mouse").click(function() { change_sex_selection('M'); });
	$("#F_mouse").click(function() { change_sex_selection('F'); });
});

function lookup(mpath, anat, youngest, oldest, sex, selected_strains)
{
	//alert('mpath: ' + mpath  + ' anat: ' + anat + ' youngest: ' + youngest + ' oldest: ' + oldest + ' sex: ' + sex); 
	//var url = "/phenotypes/query?MPATH=" + mpath + "&MA=" + anat + "&youngest=" + youngest + "&oldest=" + oldest + "&sex=" + sex + "&selected_strains=" + encodeURIComponent(selected_strains);
	//
	$.ajax(
	{
		// Send the request as a get to the url /generate/job_id?image_tag
		type:'post',
		url: '/phenotypes/query',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: {MPATH:mpath, MA:anat, youngest:youngest, oldest:oldest, sex:sex, selected_strains:selected_strains},
		dataType:'json',
		success: function(data) { process_data(data); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Status: " + textStatus); alert("Error: " + errorThrown);},
	});
}

function process_data(data_)
{
	// set the data globally
	data = data_;
	grouped_by_strain = _.toArray(_.groupBy(data, function(item){ return _.indexOf(selected_strains, item['strain']); }))
	selected_strains = _.uniq(_.pluck(data,'strain'));
	selected_sexes = get_sexes(grouped_by_strain)

	set_age_slider(get_age_range(grouped_by_strain));
	set_sex_selection(selected_sexes);
	update_table(grouped_by_strain);


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
	for (sex in severities)
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


	
	update_bar_chart(selected_strains, selected_sexes, average_severities, frequencies);

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
	var youngest = age_range[0];
	var oldest = age_range[1];
	// Now set during initial page load
	//very_youngest = (typeof(very_youngest) === "undefined") ? youngest : very_youngest;
	//very_oldest = (typeof(very_oldest) === "undefined") ? oldest : very_oldest;
	$("#age-range").slider(
	{
		range: true,
		min: very_youngest,
		max: very_oldest,
		values: [ youngest, oldest ],
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
	youngest = _.min(_.map(_.flatten(grouped_by_strain), function(item){ return item.age; }));
	oldest = _.max(_.map(_.flatten(grouped_by_strain), function(item){ return item.age; }));
	return [youngest, oldest];
}



function change_age_slider()
{

	youngest = $("#age-range").slider("option","values")[0];
	oldest = $("#age-range").slider("option","values")[1];
	lookup(mpath, anat, youngest, oldest, sex, selected_strains);
}



function set_sex_selection(sexes)
{
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
		if (clicked_sex == 'M'){ sex = 'F' }
		else {sex = 'M'}
	}
	else if (((!$("#M_mouse").hasClass('unselected')) && $("#F_mouse").hasClass('unselected') && clicked_sex == 'F') || ((!$("#F_mouse").hasClass('unselected')) && $("#M_mouse").hasClass('unselected') && clicked_sex == 'M'))
	{
		$("#"+clicked_sex+"_mouse").removeClass('unselected');
		sex = 'B'
	}
	else
	{
		if (clicked_sex == 'M'){ sex = 'F' }
		else {sex = 'M'}

		$("#"+clicked_sex+"_mouse").addClass('unselected');
		$("#"+sex+"_mouse").removeClass('unselected');
	}
	
	lookup(mpath, anat, youngest, oldest, sex, selected_strains);
}



function update_bar_chart(selected_strains, selected_sexes, average_severities, frequencies)
{

	selected_strains = selected_strains.sort();
	charted_data = [];
	
	// Generate the data
	if (selected_sexes == 'B' || selected_sexes == 'M')
	{
		var freq_m = _.map(selected_strains, function(strain)
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
	
		var sev_m = _.map(selected_strains, function(strain)
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
		var freq_f = _.map(selected_strains, function(strain)
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

		var sev_f = _.map(selected_strains, function(strain)
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
			categories: selected_strains,
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
				borderWidth: 0
			}
		},
		series: charted_data,
		events:
		{
			load: do_stats(),
			redraw: adjust_groupings(),
		}
	});
};


function do_stats()
{
	console.log("im doing stats! " + stats_timerID);
	clearInterval(stats_timerID);
	var strains = [];
	var values = [];
	
	for (sex in severities)
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
	
	//alert('mpath: ' + mpath  + ' anat: ' + anat + ' youngest: ' + youngest + ' oldest: ' + oldest + ' sex: ' + sex); 
	//var url = "/phenotypes/stats?values=" + encodeURIComponent(values) + "&strains=" + encodeURIComponent(strains);
	//
	$.ajax(
	{
		// Send the request as a get to the url /generate/job_id?image_tag
		type:'post',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		url: '/phenotypes/stats',
		data: {strains:strains, values:values},
		dataType:'json',
		success: function(id) { poll_stats(id); },
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Status: " + textStatus); alert("Error: " + errorThrown);},
	});
}

function poll_stats(id)
{
	stats_timerID = setInterval(function()
	{ 
		$.ajax(
		{
			// Send the request as a get to the url /generate/job_id?image_tag
			type:'post',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			url: '/phenotypes/check_stats',
			data: {id:id},
			dataType:'json',
			success: function(response) { check_stats(response); },
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Status: " + textStatus); alert("Error: " + errorThrown);},
		});
	}, 5000);
	console.log("im polling with a new timer! " + stats_timerID);
};


function check_stats(response)
{
	console.log("i just checked on " + stats_timerID + " and its not ready");
	// The server will return null if the job isn't done, otherwise it returns the letters
	if (response == 'Not ready.')
		{ return; }
	else
	{
		groupings = response;
		console.log(response);
		clearInterval(stats_timerID);
		
		var imageWidth = 30;
		for (var i = 0; i < chart.series[0].data.length; i++)
		{
			var x = chart.plotLeft + chart.xAxis[0].translate(i, false) - imageWidth / 2;
			var y = chart.plotTop - imageWidth / 2 + 25;
			chart_groupings[i] = chart.renderer.text(response[i].toUpperCase(), x, y).attr({ zIndex: 100 }).add();
		}
	}

};


function adjust_groupings()
{

	if (typeof(chart) === "undefined" || typeof(groupings) === "undefined")
		{ return; }

	console.log("redrawing groupings");
	var imageWidth = 30;
	for (var i = 0; i < chart.series[0].data.length; i++)
	{
		var x = chart.plotLeft + chart.xAxis[0].translate(i, false) - imageWidth / 2;
		var y = chart.plotTop - imageWidth / 2 + 25;

		chart_groupings[i].attr({ x: x, y: y});
	}
};



