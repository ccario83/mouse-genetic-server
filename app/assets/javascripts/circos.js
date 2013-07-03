// Clinton Cario
// 7/3/2013

/* =============================================================================== */ 
/* =     Code to help full screen SVG                                            = */
/* =============================================================================== */
// wait until all the resources are loaded
window.addEventListener("load", findSVGimage, false);

// fetches the document for the given embedding_element
function getSubDocument(embedding_element)
{
	if (embedding_element.contentDocument) 
	{
		return embedding_element.contentDocument;
	} 
	else 
	{
		var subdoc = null;
		try
		{
			subdoc = embedding_element.getSVGDocument();
		} catch(e) {}
		return subdoc;
	}
}

// returns SVG elements
function findSVGElements()
{
	var elm = document.querySelectorAll("#circos_img");
	for (var i = 0; i < elms.length; i++)
	{
		var subdoc = getSubDocument(elms[i])
		if (subdoc)
			subdoc.getElementById("svg").svgPan('viewport');
	}
}

// returns SVG images
function findSVGimage()
{
	var embedded_svg = document.querySelector("#circos_img");
	var embedded_doc = embedded_svg.getSVGDocument();
	var svg = embedded_doc.querySelector('svg');
	svg.svgPan('viewport');
}
