
var width = $(window).width(),
  height = $(window).height();

var vertices = d3.range(10).map(function(d) {
return [Math.random() * width, Math.random() * height];
});

var voronoi = d3.geom.voronoi()
  .clipExtent([[0, 0], [width, height]]);

var svg = d3.select("body").insert("svg", ":first-child")
  .attr("width", width)
  .attr("id", "canvas")
  .attr("height", height)
  // .on("mousemove", function() { vertices[0] = d3.mouse(this); redraw(); });

var path = svg.append("g").selectAll("path");

svg.selectAll("circle")
  .data(vertices.slice(1))
.enter().append("circle")
  .attr("transform", function(d) { return "translate(" + d + ")"; })
  .attr("r", 1.5);

redraw();

function redraw() {
path = path
    .data(voronoi(vertices), polygon);

path.exit().remove();

path.enter().append("path")
    .attr("class", function(d, i) { return "q" + (i % 9) + "-9"; })
    .attr("d", polygon);

path.order();
}

function polygon(d) {
return "M" + d.join("L") + "Z";
}
