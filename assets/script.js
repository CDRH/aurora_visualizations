current_office = "All";
// sets up d3 data
// var initial = contracts[0];
// var data = JSON.parse(JSON.stringify(initial));
initialize();

function initialize() {
  // use "All" and assume it is first in the contracts
  var data = contracts[0];
  updateTable("All");
  updateMap("All", "All");
  updateCharts("All")
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

function update(office) {
  updateTable(office);
  updateMap(current_office, office);
  updateCharts(office);
  // change current office to new selection
  current_office = office;
  // update basic UI to reflect selection
  document.getElementById("officeTitle").innerHTML = office;
  select_office_button(office);
}
