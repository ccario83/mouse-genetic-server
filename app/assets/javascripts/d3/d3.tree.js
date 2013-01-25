var selected = [];

$(document).ready(function() {
	var m = [20, 120, 20, 120],
		w = 1280 - m[1] - m[3],
		h = 800 - m[0] - m[2],
		i = 0,
		root;
		
	var tree = d3.layout.tree().size([h, w]);

	var diagonal = d3.svg.diagonal().projection(function(d) { return [d.y, d.x]; });

	var vis = d3.select("#chart").append("svg:svg")
		.attr("width", w + m[1] + m[3])
		.attr("height", h + m[0] + m[2])
		.append("svg:g")
		.attr("transform", "translate(" + m[3] + "," + m[0] + ")");


d3.json("/phenotypes/get_mpath_tree", function(json) {
  root = json[0];
  root.x0 = h / 2;
  root.y0 = 0;


  // Initialize the display to show a few nodes.
  collapse_and_deselect_subtree(root);
  collapse(root);
  select(root);
  update(root);
});

function update(source) {
  var duration = d3.event && d3.event.altKey ? 5000 : 500;

  // Compute the new tree layout.
  var nodes = tree.nodes(root).reverse();

  // Normalize for fixed-depth.
  nodes.forEach(function(d) { d.y = d.depth * 180; });

  // Update the nodes…
  var node = vis.selectAll("g.node")
      .data(nodes, function(d) { return d.id || (d.id = ++i); });

  // Enter any new nodes at the parent's previous position.
  var nodeEnter = node.enter().append("svg:g")
      .attr("class", "node")
      .attr("id",source.key)
      .attr("transform", function(d) { return "translate(" + source.y0 + "," + source.x0 + ")"; });
		
  nodeEnter.append("svg:circle").attr("r", 1e-6).style("fill", function(d) 
  { 
        var color;
        if(d._children)
            color = "lightsteelblue";
        else
            color = "#fff";
        return color; 
  }).on("click", function(d) { toggle_collapse(d); update(d); });

  nodeEnter.append("svg:text")
      .attr("x", function(d) { return d.children || d._children ? -10 : 10; })
      .attr("dy", ".35em")
      .attr("text-anchor", function(d) { return d.children || d._children ? "end" : "start"; })
      .text(function(d) { return d.name; })
      .style("fill-opacity", 1e-6)
      .on("click", function(d) { toggle_select(d); update(d); });

  // Transition nodes to their new position.
  var nodeUpdate = node.transition()
      .duration(duration)
      .attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")"; });

  nodeUpdate.select("circle").attr("r", 4.5).style("fill", function(d) 
	  { 
		    var color;
		    if(d._children)
		        color = "lightsteelblue";
		    else
		        color = "#fff";
		    return color; 
	  }).style("stroke", function(d)
	  {
		    var color;
		    if(d.select)
		        color = "yellow";
		    else
		        color = "steelblue";
		    return color;
	  });

  nodeUpdate.select("text")
      .style("fill-opacity", 1)
      .style("font-weight", function(d)
	  {
		    if(d.select)
		    	return "bold";
		    else
		        return "100";
	  }).style("text-decoration", function(d)
	  {
		    if(d.select)
		    	return "underline";
		    else
		        return "none";
	  });

  // Transition exiting nodes to the parent's new position.
  var nodeExit = node.exit().transition()
      .duration(duration)
      .attr("transform", function(d) { return "translate(" + source.y + "," + source.x + ")"; })
      .remove();

  nodeExit.select("circle")
      .attr("r", 1e-6);

  nodeExit.select("text")
      .style("fill-opacity", 1e-6);

  // Update the links…
  var link = vis.selectAll("path.link")
      .data(tree.links(nodes), function(d) { return d.target.id; });

  // Enter any new links at the parent's previous position.
  link.enter().insert("svg:path", "g")
      .attr("class", "link")
      .attr("d", function(d) {
        var o = {x: source.x0, y: source.y0};
        return diagonal({source: o, target: o});
      })
    .transition()
      .duration(duration)
      .attr("d", diagonal);

  // Transition links to their new position.
  link.transition()
      .duration(duration)
      .attr("d", diagonal);

  // Transition exiting nodes to the parent's new position.
  link.exit().transition()
      .duration(duration)
      .attr("d", function(d) {
        var o = {x: source.x, y: source.y};
        return diagonal({source: o, target: o});
      })
      .remove();

  // Stash the old positions for transition.
  nodes.forEach(function(d) {
    d.x0 = d.x;
    d.y0 = d.y;
  });
}

function select(d)
{
	//console.log(d.name+" selecting");
	// Set this node's selected state to true
	d.select = true;
	// Add this node's id to the selected list
	selected.push(d.id);
}

function select_node_and_first_children(d)
{
	if (d.children)
		d.children.forEach(select_node_and_first_children);
	select(d);
}


function select_first_children(d)
{
	if (d.children)
		d.children.forEach(select)
}

function deselect(d)
{
	//console.log(d.name + " deselecting");
	// Set this node's selected state to false
	d.select = false;
	// Remove this node's id from the selected list
	var index = selected.indexOf(d.id);
	selected.splice(index,1);
}


function collapse(d)
{
	if (d.children)
	{
		//console.log(d.name + " collapsing");
		d._children = d.children;
		d.children = null;
		d.expand = false;
	}

}

function collapse_and_deselect_subtree(d)
{
	if (d.children)
	{
		d.children.forEach(collapse_and_deselect_subtree);
		collapse(d);
	}
	deselect(d);
}


function expand(d)
{
	if (d._children)
	{
		console.log(d.name + " expanding");
		d.children = d._children;
		d._children = null;
		d.expand = true;
	}
}


// Toggle children.
function toggle(d)
{
	if (d.select==false)
	{
		// 1st click with children (collapsed unselected): expand and select children
		if (d._children && d.expand==false)
		{
			expand(d);
			select_first_children(d);
		} // 2nd click with children (expanded unselected): select the node
		else if (d.children && d.expand==true)
		{
			select(d);
		} // 1st click without children (unselected): select the node
		else
			select(d);
	} 
	else 
	{
		// 3rd click with children (expanded selected): deselect and collapse node and all subtrees
		if (d.children && d.expand==true)
		{
			collapse_and_deselect_subtree(d);
			collapse(d);
		} // 2nd click without children (selected): deselect the node
		else
			deselect(d);
	}
}


function toggle_select(d)
{	
	if (d.select==false)
		select(d);
	else
		deselect(d);
}


function toggle_collapse(d)
{
	if (d.expand==true)
		collapse(d);
	else
		expand(d);
}


$(function(){
//$('#body>svg>g').attr('transform', 'rotate(90,350,450)');
});

});
