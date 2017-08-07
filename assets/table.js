// adapted the majority of this function from
// https://bl.ocks.org/boeric/e16ad218bc241dfd2d6e
// "D3 Dynamic Array of Tables"
function updateTable(data) {
  console.log(data);
  var tableDiv = d3.select("body div.contracts");
  // select the old div and remove it
  var div = tableDiv.selectAll("div")
      .data(data, function(d) { return d.office });
  div.exit().remove();

  // enter new data and title
  var divEnter = div
    .enter()
      // .append("div").attr("class", "table-responsive")
      .append("div")
      // TODO if you want the table to be pseudo-responsive switch append("div") line comment above

  var headers = [
    "Hiring Office", "Contract Date", "Name", "Gender", "Age", "Employer",
    "Township", "County", "State", "Distance Miles", "Position", "Work Class",
    "Service (Months)", "Wages (Months)", "Comments", "Destination Class", "Group",
    "Destination Lat", "Destination Lng", "Hiring Office Lat", "Hiring Office Lng"
  ];

  // add table and header
  var tableEnter = divEnter.append("table")
      .attr("id", function(d) { return d.office })
      .attr("class", "table table-condensed table-striped table-bordered");
  tableEnter.append("thead")
    .append("tr")
      .selectAll("th")
      .data(headers)
    .enter().append("th")
      .text(function(d) { return d; });

  // append table body in new table
  tableEnter.append("tbody");

  // select all tr elements in the divs update selection
  var tr = div.select("table").select("tbody").selectAll("tr")
      .data( function(d) { return d.rows; } ); 
  // TODO do we need this?
  // tr.exit().remove();

  // bind data to rows and add columns
  tr.enter().append("tr");
  var td = tr.selectAll("td")
      .data(function(d) { return d3.values(d); });
  td.enter().append("td")
      .text(function(d) { return d; })
};
