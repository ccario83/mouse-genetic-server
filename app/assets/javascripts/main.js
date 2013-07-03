// Clinton Cario
// 7/3/2013

$(window).load(function(){
	// Flash any messages, then fade out
	$("#flash").show();
	$("#flash").delay(5000).fadeOut(1000);

	// For the phenotype explorer and any other tools that could use tooltips for navigation arrows on the sides on the screen. 
	$('#submit-right').mouseover(function() { $(this).css('opacity',1); $('#submit-right-tooltip').tooltip('show'); });
	$('#submit-right').mouseleave(function() { $(this).css('opacity',0.25); $('#submit-right-tooltip').tooltip('hide'); });
	
	$('#submit-left').mouseover(function() { $(this).css('opacity',1); $('#submit-left-tooltip').tooltip('show'); });
	$('#submit-left').mouseleave(function() { $(this).css('opacity',0.25); $('#submit-left-tooltip').tooltip('hide'); });
	
	// Set any popover (bootstrap) defaults
	$('body').popover({
		selector: '.has-popover',
		trigger: 'hover', 
		html: true,
	});
});

// A function to submit the comment form with a POST to the pages/contact URL
function submitCommentForm()
{
	$('#contact').modal('hide');
	$.ajax(
	{
		type: 'POST',
		url: '/pages/contact',
		headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
		data:$('#contact_form').serialize(),
		error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		success: function(response){ flash_notice(response); },
	});
	return false;
}

// To dynamically flash any notices using javascript 
function flash_notice(notice, alert_type)
{
	alert_type = typeof alert_type !== 'undefined' ? alert_type : 'notice';
	if($('#flash').length != 0)
		$('#flash').remove()
	$('body').append('<div id="flash" class="alert alert-' + alert_type + '">' + notice + '</div>');
	$('#flash').show(); 
	$('#flash').delay(5000).fadeOut(1000);
	return false;
}
