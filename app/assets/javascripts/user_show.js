
$(window).bind("load", function()
{
	$('#page_container').pajinate({'bootstrap':true, 'num_page_links_to_display':5, 'show_first_last':false});
	$('#managed-groups').show(); //The div is initially hidden to prevent the full list from being shown before pagination. After pagination, show it

	$('#add-group').click(function() { location.href = "/groups/new"; });
	
	
	$('#group-management-modal-close').click(function() { location.reload();  });
	
	$(function()
	{
		// Self-executing recursive animation
		(function pulse(){
			$('.pulsate').delay(200).fadeOut('slow').delay(50).fadeIn('slow',pulse);
		})();
	});
	
	$('.accept').click(function()
	{
		var id = $(this)[0].id;
		$.ajax(
		{
			// Send the request as a get to the url /phenotypes/query
			//async: false,
			type:'post',
			url: '/users/accept_group',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'json',
			success: function(response) {process_response(response)},
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
		
	});
	
	$('.decline').click(function()
	{
		var id = $(this)[0].id;
		$.ajax(
		{
			// Send the request as a get to the url /phenotypes/query
			//async: false,
			type:'post',
			url: '/users/decline_group',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'json',
			success: function(response) {process_response(response)},
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
		
	});
	
	$('.leave').click(function()
	{
		var id = $(this)[0].id;
		$.ajax(
		{
			// Send the request as a get to the url /phenotypes/query
			//async: false,
			type:'post',
			url: '/users/leave_group',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'json',
			success: function(response) {process_response(response)},
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
		
	});
	
	$('.delete').click(function()
	{
		var id = $(this)[0].id;
		$.ajax(
		{
			// Send the request as a get to the url /phenotypes/query
			//async: false,
			type:'post',
			url: '/users/delete_group',
			headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
			data: {id: id},
			dataType: 'json',
			success: function(response) {process_response(response)},
			error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
		});
		
	});
});


function process_response(response)
{
	switch(response['type'])
	{
		case 'accept':
			// Disable Accept
			$('#'+response['id']+'.accept').addClass('disabled');
			$('#'+response['id']+'.accept').unbind('click');
			$('#'+response['id']+'.accept').removeClass('accept');
			
			// Disable Decline
			$('#'+response['id']+'.decline').addClass('disabled');
			$('#'+response['id']+'.decline').unbind('click');
			$('#'+response['id']+'.decline').removeClass('decline');
			
			// Enable Leave
			$('#'+response['id']+'.icon-signout').addClass('leave');
			$('#'+response['id']+'.leave').removeClass('disabled');
			$('#'+response['id']+'.leave').click(function()
			{
				var id = $(this)[0].id;
				$.ajax(
				{
					// Send the request as a get to the url /phenotypes/query
					//async: false,
					type:'post',
					url: '/users/leave_group',
					headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
					data: {id: id},
					dataType: 'json',
					success: function(response) {process_response(response)},
					error: function(XMLHttpRequest, textStatus, errorThrown) { alert("Error: " + errorThrown);},
				});
		
			});
			
			// Solidify group icon
			$('#'+response['id']+'.icon-group').removeClass('faded');
			var row = $('#'+response['id']+'.group-management-panel')[0];
			
			// Flash success
			$(row).animate({backgroundColor:'#DFF0D8'},'fast');
			$(row).animate({backgroundColor:'white'},'fast');
		break;
		
		case 'decline':
			$('#'+response['id']+'.decline').addClass('disabled');
			$('#'+response['id']+'.decline').unbind('click');
			$('#'+response['id']+'.decline').removeClass('decline');

			var row = $('#'+response['id']+'.group-management-panel')[0];
			$(row).fadeOut('slow');
		break;
		
		case 'leave':
			$('#'+response['id']+'.leave').addClass('disabled');
			$('#'+response['id']+'.leave').unbind('click');
			$('#'+response['id']+'.leave').removeClass('leave');

			var row = $('#'+response['id']+'.group-management-panel')[0];
			$(row).fadeOut('slow');
		break;
		
		case 'delete':
			$('#'+response['id']+'.delete').addClass('disabled');
			$('#'+response['id']+'.delete').unbind('click');
			$('#'+response['id']+'.delete').removeClass('delete');

			var row = $('#'+response['id']+'.group-management-panel')[0];
			$(row).animate({backgroundColor:'#f2dede'},'fast');
			$(row).animate({backgroundColor:'white'},'fast');
			$(row).fadeOut('slow');
		break;
	}
}
