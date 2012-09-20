$('#map_options :input').change(function() {
	alert("Looking for ajax");
	$.ajax(
	{
		type:"get",
		url:'/map/update/',
		datatype:"json", 
		success: process_results,
		error: function(){}
	});
	
});

function process_results(markers)
{
    alert("I'm gonna refresh!");
}


