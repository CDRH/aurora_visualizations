// toggle for open street maps instead of stamen tiles
// var osmLayer = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
//     attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
// });

var osmLayer = L.tileLayer('http://stamen-tiles-{s}.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.{ext}', {
  attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
  subdomains: 'abcd',
  minZoom: 0,
  maxZoom: 20,
  ext: 'png'
});

var map = L.map('map', {
    center: new L.LatLng(36, -78),
    zoom: 5,
    maxZoom: 18,
    layers: [osmLayer]
});

// Note:  The below is a quick attempt at looking at the data
// colors don't matter, functions should be pulled out of other functions, etc

// CREATE WORKER GENDER LAYER
var gender = L.geoJSON(contracts, {
  style: function(feature) {
    var gender = feature.properties.workerGender;
    color = "black";
    if (gender == "female") { color = "indigo"; }
    else if (gender == "male") { color = "aquamarine"; }
    return { "color" : color, "weight" : 0.25 };
  }
});

// CREATE WORK CLASSIFICATION LAYER
var workclass = L.geoJSON(contracts, {
  style: function(feature) {
    var wclass = feature.properties.contractWorkClass;
    color = "grey";
    switch (wclass) {
      case "Agricultural" || "Farm Laborer" || "Farmer":
        color = "green";
        break;
      case "Cook" || "Domestic" || "Wash and Iron":
        color = "orange";
        break;
      case "General Laborer" || "Laborer":
        color = "red";
        break;
      case "Groom":
        color = "brown";
        break;
      case "Nurse":
        color = "blue";
        break;
      case "Other":
        color = "gold";
        break;
      case "Retail":
        color = "magenta";
        break;
      case "Waiter" || "Waitress":
        color = "indigo";
        break;
    }
    return { "color" : color, "weight" : 0.25 };
  }
});

// STYLE OF DESTINATION CIRCLES

function destinationMarkerOptions(feature) {
  count = +feature.properties.count;
  // largest destination has 196 contracts, so find percentage
  percent = count/196;
  // scale up just a bit
  size = percent*15;
  // some simply too small to see / interact with
  if (size < 3) size = 3;
  return {
    radius: size,
    color: "black",
    opacity: 1,
    weight: 0.2,
    fillColor: "grey",
    fillOpacity: 0.5
  }
};

// LOOKUP FOR GENDER KEY MOCKUP
function getColor(gender) {
  color = "black";
  if (gender == "female") {
    color = "indigo";
  } else if (gender == "male") {
    color = "aquamarine";
  }
  return color;
}

// BIND POPUP TO DESTINATION
function onEachDestination(feature, layer) {
  prop = feature.properties;
  html = "<h3>" + prop.township + ", " + prop.state + "</h3>";
  html += "<ul>";
  html += "<li>Contracts: " + prop.count + "</li>";
  html += "<li>County: " + prop.county + "</li>";
  layer.bindPopup(html);
};

// CREATE DESTINATION LAYER
var destinations = L.geoJSON(destinations, {
  onEachFeature: onEachDestination,
  pointToLayer: function(feature, latlng) {
    return L.circleMarker(latlng, destinationMarkerOptions(feature));
  }
});

// start map with the gender layer displayed
map.addLayer(gender);
map.addLayer(destinations);

// add layer controls to the map
//   first param: base layer (one selectable)
//   second param: opt. layers (mult selectable)
L.control.layers({
  "Class of Work" : workclass,
  "Gender of Worker" : gender
}, {
  "Popularity of Destination" : destinations
}).addTo(map);

// QUICK PASS AT A LEGEND PROOF OF CONCEPT
var legend = L.control({ position: "bottomright" });
legend.onAdd = function(map) {
  var div = L.DomUtil.create("div", "legend");
  div.innerHTML += "<h2>Terrible Example Legend</h2>";
  div.innerHTML += "<h3>Gender</h3>";
  ["female", "male", "unknown"].forEach(function(gender) {
    div.innerHTML += '<span class="gender ' + gender + '"></span>' + gender + '<br>';
  });

  return div;
};

legend.addTo(map);
