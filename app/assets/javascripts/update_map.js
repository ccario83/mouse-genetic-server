function marker_toggle()
{
	alert("Looking for ajax");
	$.ajax(
	{
		type:"get",
		url:'/map/update/',
		datatype:"json", 
		success: Gmaps.map.replaceMarkers,
		error: function(){alert("RoR is having trouble updating those resources.");}
	});
	
};

$(document).ready(function(){
    $('#_sequencer').change(function () { marker_toggle(); });
    $('#_bioinf').change(function () { marker_toggle(); });
    $('#_comp').change(function () { marker_toggle(); });

    Gmaps.map.customClusterer = function() {
      var url = "/assets/";
      return [{
        url: url + 'clusterer30.png',
        height: 35,
        width: 40,
      },
      {
        url: url + 'clusterer40.png', 
        height: 35,
        width: 40,
      },
      {
        url: url + 'clusterer50.png',
        height: 44,
        width: 50,
      }];
    }
});
