
	$(function(){
		$.contextMenu({
			selector: '.node', 
			trigger: 'left',
			callback: function(key, options) {
				var m = "clicked: " + key;
				window.console && console.log(m) || alert(m); 
			},
			items: {
				"edit": {name: "Edit"},
				"cut": {name: "Cut"},
				"copy": {name: "Copy"},
				"paste": {name: "Paste"},
				"delete": {name: "Delete"},
				"sep1": "---------",
				"quit": {name: "Quit", icon: "quit"}
			}
		});
	});
