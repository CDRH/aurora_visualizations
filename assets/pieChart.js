// almost entirely taken from example by Matt Castillo
// https://codepen.io/interactivematt/pen/ZGWYOO

function PieChart(dataSet, label) {
  var width = 300,
      height = 200,
    radius = Math.min(width,height) / 2;

  // set up SVG and components
  var svg = d3.select("#"+label+"Chart")
    .append("svg")
    .attr("height", height)
    .append("g")

  svg.append("g")
    .attr("class", "slices");
  svg.append("g")
    .attr("class", "labels");
  svg.append("g")
    .attr("class", "lines");

  // specifies to use contracts as numeric value for calculating pie chart angles
  var pie = d3.layout.pie()
    .sort(null)
    .value(function(d) {
      return d.contracts;
    });

  // inner radius controls the size of the center hole (0 for no hole)
  var arc = d3.svg.arc()
    .outerRadius(radius * 1.0)
    .innerRadius(radius * 0.2);

  // controls the location of the labels
  var outerArc = d3.svg.arc()
    .innerRadius(radius * 0.8)
    .outerRadius(radius * 1);

  // center the pie chart
  svg.attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

  // provide a convenient way of grabbing the labels for each item, like gender, occupation class, etc
  var property = function(d){ return d.data.property; };

  // grab the correct office's data and kick off "change"
  this.updateChart = function(office) {
    var requested = dataSet[office];
    change(requested);
  }

  // updates the pie chart to new selection smoothly
  function change(newData) {
    var duration = "500";

    // get existing values of pie chart
    var oldData = svg
      .select(".slices")
      .selectAll("path.slice")
      .data().map(function(d) { return d.data });
    if (oldData.length == 0) oldData = newData;

    /* ------- SLICE ARCS -------*/

    // bind old data to slices
    var slice = svg
      .select(".slices")
      .selectAll("path.slice")
      .data(pie(oldData), property);

    // set up each slice with class, value
    // set this._current to old data
    slice.enter()
      .insert("path")
      .attr("class", function(d) {
        return "slice "+label+"_"+d.data.property.split(" ").join("_");
      })
      .each(function(d) {
        this._current = d;
      });

    // bind new data to slices
    slice = svg
      .select(".slices")
      .selectAll("path.slice")
      .data(pie(newData), property);

    // transition gracefully between old and new values
    slice
      .transition().duration(duration)
      .attrTween("d", function(d) {
        var interpolate = d3.interpolate(this._current, d);
        var _this = this;
        return function(t) {
          _this._current = interpolate(t);
          return arc(_this._current);
        };
      });

    // bind new data to slices
    slice = svg
      .select(".slices")
      .selectAll("path.slice")
      .data(pie(newData), property);

    // remove unused pie slices
    slice
      .exit()
        .transition()
        .delay(duration)
        .duration(0)
      .remove();

    /* ------- TEXT LABELS -------*/

    // bind the old data to the labels
    var text = svg
      .select(".labels")
      .selectAll("text")
      .data(pie(oldData), property);

    // set attributes, label, etc
    text.enter()
      .append("text")
      .attr("dy", ".35em")
      .attr("class", "graph_label")
      .attr("style", "opacity: 0")
      .text(function(d) {
        return d.data.property;
      })
      .each(function(d) {
        this._current = d;
      });

    // calculation for where to position the labels
    function midAngle(d){
      return d.startAngle + (d.endAngle - d.startAngle)/2;
    }

    // bind the new data to the labels
    text = svg
      .select(".labels")
      .selectAll("text")
      .data(pie(newData), property);

    // transition labels
    text
      .transition()
      .duration(duration)
      // if there are 0 contracts, hide the label
      .style("opacity", function(d) {
        return d.data.contracts == 0 ? 0 : 1;
      })
      .attrTween("transform", function(d) {
        var interpolate = d3.interpolate(this._current, d);
        var _this = this;
        // TODO figure out what the specifics are doing below
        // besides ultimately shifting the position of the label
        return function(t) {
          var d2 = interpolate(t);
          _this._current = d2;
          var pos = outerArc.centroid(d2);
          pos[0] = radius * (midAngle(d2) < Math.PI ? 1 : -1);
          return "translate("+ pos +")";
        };
      })
      // determine if the text should start or end by the line
      // (start if on right, end if on left)
      .styleTween("text-anchor", function(d){
        var interpolate = d3.interpolate(this._current, d);
        return function(t) {
          var d2 = interpolate(t);
          return midAngle(d2) < Math.PI ? "start":"end";
        };
      });

    // bind new data to labels
    text = svg
      .select(".labels")
      .selectAll("text")
      .data(pie(newData), property);

    // remove unused labels
    text
      .exit()
      .transition()
      .delay(duration)
      .remove();

    /* ------- SLICE TO TEXT POLYLINES -------*/

    // bind old data to lines
    var polyline = svg
      .select(".lines")
      .selectAll("polyline")
      .data(pie(oldData), property);

    // styling and setting this._current
    polyline.enter()
      .append("polyline")
      .style("opacity", 0)
      .each(function(d) {
        this._current = d;
      });

    // bind new data to lines
    polyline = svg
      .select(".lines")
      .selectAll("polyline")
      .data(pie(newData), property);

    // transition gracefully to new positions
    polyline
      .transition()
      .duration(duration)
      // display only if contracts
      .style("opacity", function(d) {
        return d.data.contracts == 0 ? 0 : 1;
      })
      // TODO figure out the specifics going on here
      .attrTween("points", function(d){
        this._current = this._current;
        var interpolate = d3.interpolate(this._current, d);
        var _this = this;
        // set up the lines and corner depending on size of contracts
        return function(t) {
          var d2 = interpolate(t);
          _this._current = d2;
          var pos = outerArc.centroid(d2);
          pos[0] = radius * 0.95 * (midAngle(d2) < Math.PI ? 1 : -1);
          return [arc.centroid(d2), outerArc.centroid(d2), pos];
        };
      });

    // bind new data to lines
    polyline = svg
      .select(".lines")
      .selectAll("polyline")
      .data(pie(newData), property);

    // remove unused lines
    polyline
      .exit()
      .transition()
      .delay(duration)
      .remove();
  };
}

// make the charts!
var dclassChart = new PieChart(destination_class, "dclass");
var genderChart = new PieChart(gender, "gender");
var groupChart = new PieChart(group, "group");
var occupationChart = new PieChart(occupation, "occupation");

function updateCharts(office) {
  dclassChart.updateChart(office);
  genderChart.updateChart(office);
  groupChart.updateChart(office);
  occupationChart.updateChart(office);
}
