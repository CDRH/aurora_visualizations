/*
    Based largely upon
    http://ninjapixel.io/StackOverflow/doughnutTransition.html

    text labels adapted from http://bl.ocks.org/enjalot/1203641
      and https://stackoverflow.com/a/21844448/4154134
*/

function PieChart(dataSet, label) {
  this.width = 300,
  this.height = 200,
  this.radius = Math.min(this.width, this.height) / 2;
  this.dataSet = dataSet;

  var arc = d3.svg.arc()
    .outerRadius(this.radius - 10)
    .innerRadius(0);

  var pie = d3.layout.pie()
    .sort(null)
    .value(function(d) {
      return d.contracts;
    });

  var svg = d3.select("#"+label+"Chart").append("svg")
    .attr("id", label+"_svg")
    .attr("height", this.height)
    .attr("width", this.width)
    .append("g")
      .attr("id", "pieChart")
      .attr("transform", "translate(" + this.width / 2 + "," + this.height / 2 + ")");
  var path = svg.selectAll("path")
    .data(pie(this.dataSet["All"]))
    .enter()
      .append("path")
      .attr("class", function(d, i) {
        return label+"_slice "+label+"_"+d.data.property.split(" ").join("_");
      });

  var text = svg.selectAll("text")
    .data(pie(this.dataSet["All"]))
    .enter()
      .append("text")
        .attr("class", "chart_label")
        .attr("transform", function(d) {
          var coords = labelCoords(d);
          return "translate("+coords+")";
        });

  text
    .text( function(d) {
      return d.data.property+": "+d.data.contracts;
    });

  path.transition()
    .duration(500)
    .attr("d", arc)
    .each(function(d) {
      this._current = d;
    });

  function labelCoords(d) {
    var c = arc.centroid(d);
    var x = c[0]*1.7;
    var y = c[1]*1.7;
    return x+","+y;
  }

  function redrawPath() {
    path.transition().duration(750).attrTween("d", arcTween);
  }

  function redrawText() {
    text
      .data(data)
      .transition()
      .duration(750)
      .attr("transform", function(d) {
        var coords = labelCoords(d);
        return "translate(" + coords + ")";
      })
      .text(function(d) {
        return d.data.property+": "+d.data.contracts;
      })
  }

  this.updateChart = function(office) {
    data = pie(this.dataSet[office]);
    path.data(data);
    text.data(data);
    redrawPath();
    redrawText();
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
}

var dclassChart = new PieChart(destination_class, "dclass");
var genderChart = new PieChart(gender, "gender");
var occupationChart = new PieChart(occupation, "occupation");

function updateCharts(office) {
  dclassChart.updateChart(office);
  genderChart.updateChart(office);
  occupationChart.updateChart(office);
}
