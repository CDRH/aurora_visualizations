current_office = "All";

function changeOffice(office) {
  document.getElementById("officeTitle").innerHTML = office;
  var hiring_office_contracts = contracts.find(function(table) { return table.office == office });
  update(office, hiring_office_contracts);

}

// d3 stuff here
var initial = contracts[0];
var data = JSON.parse(JSON.stringify(initial));
update("All", data);

function update(office, data) {
  updateMap(current_office, office);
  updateTable([data]);
  current_office = office;
};
