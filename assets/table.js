// adapted the majority of this function from
// https://bl.ocks.org/boeric/e16ad218bc241dfd2d6e
// "D3 Dynamic Array of Tables"
function updateTable(office, sort) {
  console.log("updating table " + sort);
  sort = sort || "contract_date";
  console.log("sort " + sort);
  var officeRows = contracts.find(function(table) {
    return table.office == office
  });

  var sortedRows = officeRows.rows.sort(function(a, b) {
    // distance can be sorted numerically (age, service and wages not so much)
    var asort = a[sort];
    var bsort = b[sort];
    if (sort === "distance_miles") {
      asort = parseInt(asort) || 0;
      bsort = parseInt(bsort) || 0;
    }
    if (asort < bsort) { return -1; }
    if (asort > bsort) { return 1; }
    return 0;
  });

  officeRows.rows = sortedRows;
  // If somebody wants to tell me how to get d3 to do what I want without
  // wrapping one of the steps in an array, I would be very happy to learn
  // but my first pass at it with an object was a complete failure
  var data = [officeRows];
  var tableDiv = d3.select("body div.contracts");

  // d3 is smart enough to recognize that the office's data has not changed
  // if you are only sorting existing, so we remove ALL of the existing table
  // before rebuilding it with the newly selected sort
  tableDiv.selectAll("div").remove();
  // bind the new data to the div, then remove all the rows using the old data
  var div = tableDiv.selectAll("div")
      .data(data, function(d) { return d.office });
  div.exit().remove();

  // append a div to hold the information
  var divEnter = div.enter()
      .append("div")

  // typing them out instead of a programmatic solution for ease of alteration
  var headers = {
    "hiring_office": "Hiring Office",
    "contract_date": "Contract Date",
    "name": "Name",
    "gender": "Gender",
    "age": "Age",
    "employer": "Employer",
    "township": "Township",
    "county": "County",
    "state": "State",
    "distance_miles": "Distance (Miles)",
    "position": "Position",
    "work_class": "Work Class",
    "service_months": "Service (Months)",
    "wages_months": "Wages (Months)",
    "destination_class": "Destination Class",
    "group": "Group"
  }

  // add table and header
  var tableEnter = divEnter.append("table")
      .attr("id", function(d) { return d.office })
      .attr("class", "table table-condensed table-striped table-bordered");
  tableEnter.append("thead")
    .append("tr")
      .selectAll("th")
      .data(d3.keys(headers))
    .enter().append("th").append("a")
      .text(function(d) { return headers[d]; })
      .on('click', function(d) {
        updateTable(office, d);
      })
      .attr("class", function(d) {
        if (d === sort) {
          return "table-col-sorted"
        }
      })

  // append table body in new table
  tableEnter.append("tbody");

  // select all tr elements in the divs update selection
  var tr = div.select("table").select("tbody").selectAll("tr")
      .data( function(d) { return d.rows; } ); 
  tr.exit().remove();

  // bind data to rows and add columns
  tr.enter().append("tr");
  var td = tr.selectAll("td")
      .data(function(d) { return d3.values(d); });
  td.enter().append("td")
      .text(function(d) { return d; })
};
