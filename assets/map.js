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

var office_layers = {};
// CREATE LAYER FOR EACH GEOJSON OBJECT
for (var key in geojson) {
  var layer = L.geoJSON(geojson[key], {
    style: function(feature) {
      return { "weight" : 1 };
    },
    onEachFeature: onEachLine
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

// CREATE POPUP FOR EACH ROUTE
function onEachLine(feature, layer) {
  var props = feature.properties;
  var html = "<div class='contractProperties'>";
  html += "<h4>"+props.office+" to "+props.destination+"</h3>";
  props.contracts.forEach(function(prop) {
    html += "<strong>" + prop.name + "</strong>";
    html += "<ul class='contractDesc'>";
      html += "<li>Worker Age: " + prop.age + "</li>";
      html += "<li>Worker Gender: " + prop.gender + "</li>";
      html += "<li>Work Type: " + prop.work_class + "</li>";
      html += "<li>Contract Date: " + prop.contract_date + "</li>";
      html += "<li>Contract Employer: " + prop.employer + "</li>";
      html += "<li>Wages: " + prop.wages_month + "</li>";
      html += "<li>Period: " + prop.service_months + "</li>";
    html += "</ul>"
  });
  html += "</div>";
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
