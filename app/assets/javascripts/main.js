// Flash any messages
$(window).load(function(){
	$("#notice").show();
	$("#notice").delay(5000).fadeOut(1000);

	$('#submit-right').mouseover(function() { $(this).css('opacity',1); $('#submit-right-tooltip').tooltip('show'); });
	$('#submit-right').mouseleave(function() { $(this).css('opacity',0.25); $('#submit-right-tooltip').tooltip('hide'); });
	
	$('#submit-left').mouseover(function() { $(this).css('opacity',1); $('#submit-left-tooltip').tooltip('show'); });
	$('#submit-left').mouseleave(function() { $(this).css('opacity',0.25); $('#submit-left-tooltip').tooltip('hide'); });
});


