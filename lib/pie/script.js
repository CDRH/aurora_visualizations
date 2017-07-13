/*
    Stolen pretty much entirely from
    http://ninjapixel.io/StackOverflow/doughnutTransition.html
*/

var width = 800,
height = 250,
radius = Math.min(width, height) / 2;

var color = d3.scale.ordinal()
.range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]);

var arc = d3.svg.arc()
.outerRadius(radius - 10)
.innerRadius(0);

var pie = d3.layout.pie()
.sort(null)
.value(function(d) {
  return d.totalContracts;
});

var svg = d3.select("#genderChart").append("svg")
  .attr("width", width)
  .attr("height", height)
  .append("g")
    .attr("id", "pieChart")
    .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

var path = svg.selectAll("path")
  .data(pie(gender_by_offices["All Offices"]))
  .enter()
    .append("path");

path.transition()
  .duration(500)
  .attr("fill", function(d, i) {
   return color(d.data.gender);
  })
  .attr("d", arc)
  .each(function(d) {
    this._current = d;
}); // store the initial angles

function change(office) {
  data = gender_by_offices[office];
  path.data(pie(data));
  path.transition().duration(750).attrTween("d", arcTween); // redraw the arcs

}

// Store the displayed angles in _current.
// Then, interpolate from _current to the new angles.
// During the transition, _current is updated in-place by d3.interpolate.

function arcTween(a) {
  var i = d3.interpolate(this._current, a);
  this._current = i(0);
  return function(t) {
    return arc(i(t));
  };
}
