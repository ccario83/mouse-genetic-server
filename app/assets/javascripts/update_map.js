function marker_toggle()
{
	check_boxes = [];
	// Insert the value
	$('#_sequencer').is(':checked')?check_boxes.push('Sequencer'):null;
	$('#_bioinf').is(':checked')?check_boxes.push('Bioinformatic Resource'):null;
	$('#_comp').is(':checked')?check_boxes.push('Computational Resource'):null;
	
	var check_boxes = JSON.stringify(check_boxes)
	$.getJSON('map/update', { resource_types : check_boxes }, function(data){ Gmaps.map.replaceMarkers(data); } );
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
    };
    
    marker_toggle();
});
