$(document).ready(function()
{
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
			selectMode: 2,
			onSelect: function(select, node) {
				// Display list of selected nodes
				var selNodes = node.tree.getSelectedNodes();
				// Set the selected array to the selected nodes
				selected = $.map(selNodes, function(node){
					   return node.data.key;
				});
			},
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
			selectMode: 2,
			onSelect: function(select, node) {
				// Display list of selected nodes
				var selNodes = node.tree.getSelectedNodes();
				// Set the selected array to the selected nodes
				selected = $.map(selNodes, function(node){
					   return node.data.key;
				});
			},
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
	
	
		$("#btnToggleSelect").click(function(){
			$("#tree").dynatree("getRoot").visit(function(node){
				node.toggleSelect();
			});
			return false;
		});
		$("#btnDeselectAll").click(function(){
			$("#tree").dynatree("getRoot").visit(function(node){
				node.select(false);
			});
			return false;
		});
		$("#btnSelectAll").click(function(){
			$("#tree").dynatree("getRoot").visit(function(node){
				node.select(true);
			});
			return false;
		});
		
		// Expand the root node
		//$("#mpath_tree").dynatree("getRoot").visit(function(node){node.expand(true);});
});
