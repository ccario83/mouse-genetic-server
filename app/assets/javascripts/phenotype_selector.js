// Clinton Cario
// 7/3/2013


// This function is a hack to override the default node click behavior of dynatree:
// 1) Select root and all children
// 2) Select just root
// 3) Select just children
// 4) Select none
// 5) Goto 1
function custom_select(select, node) 
{
	// Define the parent and current node li elements
	var parent_li = $($(node.parent.li).find('span')[0]);
	var node_li = $(node.li);
	var node_li_span = $(node_li.find('span')[0]);
	// Fix to prevent parent node from becoming selected if singleton child
	if (node.parent.childList.length==1)
	{
		node.parent.bSelected=false;
		parent_li.removeClass('dynatree-selected');
	}
	
	// Fix to allow parent nodes to be last node in tree to be fully selected 
	if (node.childList.length > 0)
	{
		if ( node.bSelected && (!(node_li_span.hasClass('dynatree-swc'))) && (!(node_li_span.hasClass('dynatree-s'))) && (!(node_li_span.hasClass('dynatree-jc'))) )
		{
			//console.log('Not selected => Selected w/ Children');
			if (!(node.bExpanded)) { node.toggleExpand(); }
			if (!(node.bSelected)) { node.toggleSelect(); }
			// Select this and all children
			// Already done
			// Set flag for next click
			node_li_span.addClass('dynatree-swc');
		}
		else if (node_li_span.hasClass('dynatree-swc'))
		{
			//console.log('Selected w/ Children => Selected')
			if (!(node.bExpanded)) { node.toggleExpand(); }
			// Select this node
			node_li_span.addClass('dynatree-selected')
			node.bSelected = true;
			// Partially select parents
			while (node.parent)
			{
				node = node.parent;
				$($(node.li).find('span')[0]).addClass('dynatree-partsel');
			}
			node_li_span.removeClass('dynatree-swc');
			node_li_span.addClass('dynatree-s');
		}
		else if (node_li_span.hasClass('dynatree-s'))
		{
			//console.log('Selected => Just Children');
			if (!(node.bExpanded)) { node.toggleExpand(); }
			// Deselect parent
			if (node.bSelected) { node_li_span.removeClass('dynatree-selected'); }
			node.beSelected = false;
			// Select children
			for (var i = 0; i < node.childList.length; i++)
			{
				// Will expand child subtrees one level
				//if (!(node.childList[i].bSelected)) { node.childList[i].toggleSelect(); }
				if (!(node.childList[i].bSelected))
				{
					$($(node.childList[i].li).find('span')[0]).addClass('dynatree-selected');
					node.childList[i].bSelected = true;
				}
			}
			// Partially select this node
			node_li_span.addClass('dynatree-partsel');
			// Partially select parents
			while (node.parent)
			{
				node = node.parent;
				$($(node.li).find('span')[0]).addClass('dynatree-partsel');
			}
			node_li_span.removeClass('dynatree-s');
			node_li_span.addClass('dynatree-jc');
		}
		else if (node_li_span.hasClass('dynatree-jc'))
		{
			//console.log('Just Children => None');
			if (node.bExpanded) { node.toggleExpand(); }
			if (node.bSelected) { node.toggleSelect(); }
			node_li_span.removeClass('dynatree-jc');
		}
	}
	
	// Display list of selected nodes
	var selNodes = node.tree.getSelectedNodes();
	//$.each(selNodes, function(idx, x) { if (x.parent.bExpanded) {console.log(x.data.title);} })
	// Set the selected array to the selected nodes
	selected = $.map(selNodes, function(node){
		return node.data.key;
	});
}


// Attach dynatree objects to the two trees (see dynatree documentation)
$(function()
{
	$("#mpath_tree").dynatree({
		initAjax: {
			url: "/phenotypes/get_mpath_tree",
			data: { mode: "all" }
		},
		onActivate: function(node) {
			$("#echoActive").text(node.data.title);
		},
		onDeactivate: function(node) {
			$("#echoActive").text("-");
		},
		checkbox: true,
		selectMode: 3,
		onSelect: function(select, node) { custom_select(select,node); },
		onClick: function(node, event) {
			// We should not toggle, if target was "checkbox", because this
			// would result in double-toggle (i.e. no toggle)
			if( node.getEventTargetType(event) == "title" )
				node.toggleSelect();
		},
		onKeydown: function(node, event) {
			if( event.which == 32 ) {
				node.toggleSelect();
				return false;
			}
		},
		onPostInit: function (isReloading, isError) {
			if (isReloading == false && isError == false){
				$("#mpath_tree").dynatree("getRoot").visit(function(node){
					node.expand(true); 
					return false;
				});
			}
		},
		// The following options are only required, if we have more than one tree on one page:
		cookieId: "dynatree-mpath",
		idPrefix: "dynatree-mpath-"
	});
});

	
$(function()
{
	$("#anat_tree").dynatree({
		initAjax: {
			url: "/phenotypes/get_anat_tree",
			data: { mode: "all" }
		},
		onActivate: function(node) {
			$("#echoActive").text(node.data.title);
		},
		onDeactivate: function(node) {
			$("#echoActive").text("-");
		},
		checkbox: true,
		selectMode: 3,
		onSelect: function(select, node) { custom_select(select,node); },
		onClick: function(node, event) {
			// We should not toggle, if target was "checkbox", because this
			// would result in double-toggle (i.e. no toggle)
			if( node.getEventTargetType(event) == "title" )
				node.toggleSelect();
		},
		onKeydown: function(node, event) {
			if( event.which == 32 ) {
				node.toggleSelect();
				return false;
			}
		},
		// The following options are only required, if we have more than one tree on one page:
		cookieId: "dynatree-anat",
		idPrefix: "dynatree-anat-"
	});
});



$(document).ready(function()
{
	var loadTimer = setInterval(function(){check_trees()}, 200);

	// Wait for the trees to fully load before generating the term search box's auto complete list
	function check_trees()
	{
		var mpath_isLoading = $("#mpath_tree").dynatree("getRoot").isLoading();
		var anat_isLoading = $("#anat_tree").dynatree("getRoot").isLoading();

		if (!mpath_isLoading && !anat_isLoading) 
		{
			clearInterval(loadTimer);
			// Expand the first nodes
			$("#mpath_tree").dynatree("getRoot").visit(function(node){node.expand(true); return false;});
			$("#anat_tree").dynatree("getRoot").visit(function(node){node.expand(true); return false;});
			
			var mpath_first_node = $("#mpath_tree").dynatree("getRoot").childList[0];
			var anat_first_node = $("#anat_tree").dynatree("getRoot").childList[0];
			var mpath_term_list=[];
			var anat_term_list=[];
			make_autocomplete_list(mpath_first_node, mpath_term_list);
			make_autocomplete_list(anat_first_node, anat_term_list);

			// Make the auto complete lists
			$('#mpath_search').autocomplete(
			{ 
				source: mpath_term_list, 
				minLength: 3, 
				select: function(event, ui)
				{ 
					$('#mpath_tree').dynatree('getTree').activateKey(ui.item.value);
					$('#mpath_search').val(ui.item.label);
					return false; // Return false to cancel the event, which prevents jQuery from replacing the field with the 'value' (which is just the ID)
				}
			});
			
			$("#anat_search").autocomplete(
			{
				source: anat_term_list, 
				minLength: 3, 
				select: function(event, ui)
				{ 
					$('#anat_tree').dynatree('getTree').activateKey(ui.item.value);
					$('#anat_search').val(ui.item.label);
					return false; // Return false to cancel the event, which prevents jQuery from replacing the field with the 'value' (which is just the ID)
				} 
			});
		}
	};
	
	// Have the trees' search boxes respond to the 'Enter' key by searching their trees
	$('#mpath_search').keypress(function (e)
	{
		if (e.which == 13)
		{
			search_tree($("#mpath_tree").dynatree("getRoot").childList[0], $('#mpath_search').val());
			return false;	//Prevent page refresh by returning false
		}
	});

	$('#anat_search').keypress(function (e)
	{
		if (e.which == 13)
		{
			search_tree($("#anat_tree").dynatree("getRoot").childList[0], $('#anat_search').val());
			return false;	//Prevent page refresh by returning false
		}
	});

// Fix for height issue so trees fill most of the page (thanks Matt!)
$('.dynatree-container').height($(window).height() - $('.dynatree-container').position().top - 75 );
});

// Fix for height issue on window resize or container resize
$(window).resize(function() { $('.dynatree-container').height( $(window).height() - $('.dynatree-container').position().top - 75 ) });
$('.dynatree-container').resize(function() { $('.dynatree-container').height( $(window).height() - $('.dynatree-container').position().top - 75 ) });


// Generate an auto complete list of terms for the trees' search boxes based on nodes' terms
function make_autocomplete_list(node, list)
{
	if (node.childList)
	{
		for (var i = 0; i < node.childList.length; i++)
			make_autocomplete_list(node.childList[i], list);
	}
	var term = node.data.title + "  [ID=" + node.data.key + "]";
	list.push({ 'label': term, 'value': node.data.key});
}

// Look for a term in the node list
function search_tree(node, term)
{
	if (node.data.key == term || node.data.title == term)
	{
		node.tree.activateKey(node.data.key);
	}
	else if(node.childList)
		for (var i = 0; i < node.childList.length; i++)
			search_tree(node.childList[i], term);
}

// Send the selected terms to the server
function lookup()
{
	var mpath_ids = [];
	var mpath_nodes = $("#mpath_tree").dynatree("getSelectedNodes");
		for (var i = 0; i < mpath_nodes.length; i++)
			mpath_ids.push(mpath_nodes[i].data.key);
	
	var anat_ids = [];
	var anat_nodes = $("#anat_tree").dynatree("getSelectedNodes");
		for (var i = 0; i < anat_nodes.length; i++)
			anat_ids.push(anat_nodes[i].data.key);
	
	if (mpath_ids.length==0 || anat_ids.length==0)
	{
		alert("Please select at least one of both a pathology term and an anatomy term.");
		return;
	}
	
	post_to_url('/phenotypes/show', { 'mpath_ids':JSON.stringify(mpath_ids), 'anat_ids':JSON.stringify(anat_ids) });
}



/* =============================================================================== */ 
/* =     Function to post data for processing  (thanks stackoverflow!)           = */
/* =============================================================================== */
function post_to_url(path, params, method)
{
	method = method || "post";

	var form = document.createElement("form");
	form.setAttribute("method", method);
	form.setAttribute("action", path);
	$(form).css({ position: 'absolute', top: '0px', left: '0px', display: 'none'});

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
