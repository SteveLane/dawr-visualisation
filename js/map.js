// Script to hold mapping stuff
var width = 800,
    height = 600;

// Create the svg element
var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height)
    .style("border", "1px solid black");

var projection = d3.geoIdentity();

var path = d3.geoPath()
    .projection(projection);

// Now draw the map
d3.json("data/aust-topo.json", function(error, aust) {
    if (error) return console.error(error);
    var geojson = topojson.feature(aust, aust.objects.states);

    // Expand to bounds
    projection
	.scale(1)
	.translate([0, 0]);
    var b = path.bounds(geojson),
	s = .95 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height),
	t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2];
    projection
	.scale(s)
	.translate(t);

    // Draw and add mouseover events
    svg.selectAll("path")
	.data(geojson.features)
	.enter()
	.append("path")
	.attr("d", path)
	.style("stroke", "#fff")
	.style("stroke-width", "1")
	.style("fill", "black")
	.on("mouseover", function(d) {
	    d3.select(this)
		.transition()
      		.duration(200)
		.style("fill", "#F78536");
	})
	.on("mouseout", function(d) {
	    projection
		.scale(s)
	    d3.select(this)
		.transition()
		.duration(500)
		.style("fill", "black");
	});
});
