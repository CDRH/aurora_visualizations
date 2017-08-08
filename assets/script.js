current_office = "All";
// sets up d3 data
var initial = contracts[0];
var data = JSON.parse(JSON.stringify(initial));
update("All", data);


function changeOffice(office) {
  document.getElementById("officeTitle").innerHTML = office;
  var hiring_office_contracts = contracts.find(function(table) { return table.office == office });
  update(office, hiring_office_contracts);
}

function select_office_button(office) {
  buttons = document.getElementsByClassName("btn-office");
  buttonLength = buttons.length;
  for (var i = 0; i < buttonLength; i++) {
    var btn = buttons[i];
    if (btn.innerHTML == office) {
      btn.className += " active";
    } else {
      btn.className = btn.className.replace(" active", "");
    }
  }
}

function update(office, data) {
  select_office_button(office);
  updateMap(current_office, office);
  updateTable([data]);
  current_office = office;
}
