// Flash any messages
$(window).load(function(){
	$("#notice").show();
	$("#notice").delay(5000).fadeOut(1000);

	$('#submit-right').mouseover(function() { $(this).css('opacity',1); $('#submit-right-tooltip').tooltip('show'); });
	$('#submit-right').mouseleave(function() { $(this).css('opacity',0.25); $('#submit-right-tooltip').tooltip('hide'); });
	
	$('#submit-left').mouseover(function() { $(this).css('opacity',1); $('#submit-left-tooltip').tooltip('show'); });
	$('#submit-left').mouseleave(function() { $(this).css('opacity',0.25); $('#submit-left-tooltip').tooltip('hide'); });
});

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

function flash_notice(notice)
{
	if($('#notice').length != 0)
		$('#notice').remove()
	$('body').append('<div id="notice" class="alert fade in"><button type="button" class="close" data-dismiss="alert">×</button>'+notice+'</div>');
	$('#notice').show(); 
	$('#notice').delay(5000).fadeOut(1000);
	return false;
}
