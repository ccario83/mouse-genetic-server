//Debug temp;
var data;
var load;

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



	// Initialize the age range slider
	set_age_range(VERY_YOUNGEST, VERY_OLDEST);
	lookup(MPATH_ID_LIST, ANAT_ID_LIST, ALL_STRAINS, VERY_YOUNGEST, VERY_OLDEST, '', 'B');
	$("#M_mouse").click(function() { change_sexes('M'); });
	$("#F_mouse").click(function() { change_sexes('F'); });
	// The age_range on change is set by set_age_selection() on the initial lookup call; it doesn't work when it is set here
	$("#code").change(function() { change_code(); });
	load = $('#chart').html();
	
	var youngest = get_age_range()[0];
	var oldest = get_age_range()[1];
	$('#submit-right').click(function () { post_to_url('/phenotypes/submit', {mpath_id_list:JSON.stringify(MPATH_ID_LIST), anat_id_list:JSON.stringify(ANAT_ID_LIST), selected_strains:JSON.stringify(ALL_STRAINS), youngest:youngest, oldest:oldest, code:get_code(), sex:get_sexes()}); });
});


/* =============================================================================== */ 
/* =     Functions to lookup and process data requested by the interface         = */
/* =============================================================================== */
function lookup(mpath_id_list, anat_id_list, selected_strains, youngest, oldest, code, sex)
{

	$('#chart').html(load);
	console.log("AJAX: Requesting new filtered strain data...");
	// Send the request for new data to the server
	$.ajax(
	{
		// Send the request as a get to the url /phenotypes/query
		//async: false,
		type:'post',
		url: '/phenotypes/query',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data: {mpath_id_list:mpath_id_list, anat_id_list:anat_id_list, selected_strains:selected_strains, youngest:youngest, oldest:oldest, code:code, sex:sex},
		dataType: 'json',
		success: function(response) {process_data(response)},
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
	});
}


function process_data(response)
{
	// set the data globally for debugging
	data = response;

	// Get the responding values
	//selected_strains = response['strains'];
	var youngest = response['youngest'];
	var oldest = response['oldest'];
	var sex = response['sex'];

	// Update page elements
	set_sexes(sex);
	set_age_range(youngest, oldest);

	if ((typeof(data.severities['M']) === 'undefined') && (typeof(data.severities['F']) === 'undefined'))
		{ $('#no-results').css('display','block'); $('#submit-right').css('display','none'); }
	else 
		{ update_bar_chart(ALL_STRAINS, sex, response['severities'], response['frequencies']); }

}

/* =============================================================================== */ 
/* =     Functions to get/set current selection values                           = */
/* =============================================================================== */
function get_sexes()
{
	if (!$("#M_mouse").hasClass('unselected') && (!$("#F_mouse").hasClass('unselected')))
		{ return 'B'; }
	else if ($("#M_mouse").hasClass('unselected'))
		{ return 'F'; }
	else
		{ return 'M'; }
}

function set_sexes(sex)
{
	var new_sex = '';
	if (sex.length>1)
	{new_sex = 'B';}
	else
	{new_sex = sex;}

	$("#M_mouse").addClass('unselected');
	$("#F_mouse").addClass('unselected');
	if (new_sex == 'B')
	{
		$("#M_mouse").removeClass('unselected');
		$("#F_mouse").removeClass('unselected');
	}
	else { $("#"+new_sex+"_mouse").removeClass('unselected'); }
}


function get_age_range()
{ return [$("#age-range").slider("option","values")[0], $("#age-range").slider("option","values")[1]] }

function set_age_range(youngest, oldest)
{
	$("#age-range").slider(
	{
		range: true,
		min: VERY_YOUNGEST,
		max: VERY_OLDEST,
		values: [ youngest, oldest ],
		slide: function( event, ui )
		{
			$( "#ages" ).val(ui.values[ 0 ] + " - " + ui.values[ 1 ] );
		}, 
	});
	$( "#ages" ).val($( "#age-range" ).slider( "values", 0 ) + " - " + $( "#age-range" ).slider( "values", 1 ) );
	// Set the stop function here cause it doesn't like it in document.ready()
	$("#age-range").slider("option", "stop", function() { change_age_range() } );
}


function get_code()
{ return $('#code').val(); }

function set_code(code)
{ $('#code').val(code); }


/* =============================================================================== */ 
/* =     Functions to handle interface selection changes                         = */
/* =============================================================================== */
function change_age_range()
{
	// Clear the code value so the age selection will filter with slider values
	set_code('');
	var youngest = get_age_range()[0];
	var oldest = get_age_range()[1];
	lookup(MPATH_ID_LIST, ANAT_ID_LIST, ALL_STRAINS, youngest, oldest, get_code(), get_sexes());
}

function change_code()
{
	// Age slider will update when the lookup function returns
	lookup(MPATH_ID_LIST, ANAT_ID_LIST, ALL_STRAINS, VERY_YOUNGEST, VERY_OLDEST, get_code(), get_sexes());
}

function change_sexes(clicked_sex)
{
	// If both sexes are currently selected
	if (get_sexes()=='B')
	{
		// Set the clicked one to unselected
		$("#"+clicked_sex+"_mouse").addClass('unselected');
	}
	// If the unselected sex was clicked
	else if ((get_sexes()=='M' && clicked_sex == 'F') || (get_sexes()=='F' && clicked_sex == 'M'))
	{
		// Set it to selected
		$("#"+clicked_sex+"_mouse").removeClass('unselected');
	}
	// A selected sex was clicked
	else
	{
		// Set the other sex to selected
		var other_sex = '';
		if (clicked_sex == 'M'){ other_sex = 'F'; }
		else {other_sex = 'M';}
		$("#"+clicked_sex+"_mouse").addClass('unselected');
		$("#"+other_sex+"_mouse").removeClass('unselected');
	}
	var youngest = get_age_range()[0];
	var oldest = get_age_range()[1];
	lookup(MPATH_ID_LIST, ANAT_ID_LIST, ALL_STRAINS, VERY_YOUNGEST, VERY_OLDEST, get_code(), get_sexes());
}



/* =============================================================================== */ 
/* =     Functions to update charted data                                        = */
/* =============================================================================== */
function update_bar_chart(selected_strains, sex, severities, frequencies)
{
	// Strain label formatter helper
	window.defined_strains = [];
	var charted_data = [];
	
	// Generate the data
	if ((sex == 'B' || sex == 'M') && !(typeof(frequencies['M']) === "undefined"))
	{
		var freq_m = frequencies['M'];
		var sev_m = severities['M'];
		
		// Check for defined strains
		for (var key in freq_m) { defined_strains.push(key); }
		for (var key in sev_m) { defined_strains.push(key); }
		
		freq_m =  _.map(selected_strains, function(strain){ return typeof(freq_m[strain])==='undefined'? 0:parseFloat(freq_m[strain].toFixed(2)); });
		charted_data.push(
		{
			name: 'Frequency M',
			color: '#002E69',
			data: freq_m,
			yAxis: 0,
		});
		// Convert to a list respective to selected_strains strain order
		
		sev_m =  _.map(selected_strains, function(strain){ return typeof(sev_m[strain])==='undefined'? 0:parseFloat(sev_m[strain].toFixed(2)); });
		charted_data.push(
		{
			name: 'Severity M',
			color: '#80C4FF',
			data: sev_m,
			yAxis: 1,
		});
	}
	
	
	if ((sex == 'B' || sex == 'F') && !(typeof(frequencies['F']) === "undefined"))
	{
		var freq_f = frequencies['F'];
		var sev_f = severities['F'];

		// Check for defined strains
		for (var key in freq_f) { defined_strains.push(key); }
		for (var key in sev_f) { defined_strains.push(key); }

		freq_f =  _.map(selected_strains, function(strain){ return typeof(freq_f[strain])==='undefined'? 0:parseFloat(freq_f[strain].toFixed(2)); });		
		charted_data.push(
		{
			name: 'Frequency F',
			color: '#8F0F2A',
			data: freq_f,
			yAxis: 0,
		});
		

		sev_f =  _.map(selected_strains, function(strain){ return typeof(sev_f[strain])==='undefined'? 0:parseFloat(sev_f[strain].toFixed(2)); });
		charted_data.push(
		{
			name: 'Severity F',
			color: '#FF808D',
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
				formatter: function() {
					if (defined_strains.indexOf(this.value)>-1){
						return '<span style="fill: black;">' + escape(this.value) + '</span>';
					} else {
						return '<span style="fill: #ddd;">' + escape(this.value) + '</span>';
					}
				},
				rotation: 90,
				align: "left",	
			},
		},
		yAxis:
		[
			{  // Frequency yAxis
				min: 0,
				title: { text: 'Frequency' },
				labels: { formatter: function() { return this.value*100 + '%'; } },
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
			formatter: function()
			{
				var sex = (this.series.name == 'Frequency M' || this.series.name=='Severity M')? 'M' : 'F';
				var measure = (this.series.name == 'Frequency M' || this.series.name=='Frequency F')? 'frequencies' : 'severities';
				var n = data['ns'][sex][this.key];
				if (measure == 'frequencies')
					{ return this.x + ': ' + (this.y*100).toFixed(0) + '%, n = ' + n }
				else
					{ return this.x +': '+ this.y.toFixed(2) + ', n = ' + n; }
				
			}
		},
		plotOptions:
		{
			column:
			{
				pointPadding: 0.2,
				borderWidth: 0, 
			}
		},
		series: charted_data,
	});
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
