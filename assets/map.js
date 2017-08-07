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

// CREATE OFFICE LAYERS
var office_mapping = {
  "Alexandria" : { "color" : "yellow" },
  "All" : { "color" : "black" },
  "Camp Nelson" : { "color" : "orange" },
  "Chattanooga" : { "color" : "red" },
  "Louisville" : { "color" : "green" },
  "Memphis" : { "color" : "blue" },
  "Petersburg" : { "color" : "magenta" },
  "Wisewell Barracks" : { "color" : "indigo" }
};

var office_layers = {};
// CREATE LAYER FOR EACH GEOJSON OBJECT
for (var key in office_mapping) {
  var office = office_mapping[key];
  var layer = L.geoJSON(geojson[key], {
    style: function(feature) {
      return { "color" : office["color"], "weight" : 0.25 };
    }
  })
  office_layers[key] = layer;
};

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
var destination_layer = L.geoJSON(destinations, {
  onEachFeature: onEachDestination,
  pointToLayer: function(feature, latlng) {
    return L.circleMarker(latlng, destinationMarkerOptions(feature));
  }
});

// start map with destination layer displayed
map.addLayer(destination_layer);

// add layer controls to the map
//   first param: base layer (one selectable)
//   second param: opt. layers (mult selectable)
L.control.layers({}, {"Popularity of Destination": destination_layer}, { collapsed: false }).addTo(map);


function updateMap(current, requested) {
  map.removeLayer(office_layers[current]);
  map.addLayer(office_layers[requested]);
  map.fitBounds(office_layers[requested].getBounds());
  destination_layer.clearLayers();
  // TODO plug in the correct destination data
  destination_layer.addData(destinations);
};
