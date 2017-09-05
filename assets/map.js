// STYLE DESTINATION CIRCLES
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
  html = "<h3>" + prop.label + "</h3>";
  html += "<p>Contracts: " + prop.count + "</p>";
  layer.bindPopup(html);
};

// CREATE POPUP FOR EACH ROUTE
function onEachLine(feature, layer) {
  var props = feature.properties;
  var html = "<div class='contractProperties'>";
  html += "<h4>"+props.office+" to "+props.destination+"</h3>";
  html += "<p>"+props.date+": "+props.contracts.length+" contract(s)</p>";
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

function updateMap(current, requested) {
  // alter the map boundaries to zoom in on office routes
  map.fitBounds(office_layers[requested].getBounds());
  // swap the destinations
  destination_layer.clearLayers();
  destination_layer.addData(destination_geojson[requested]);
  // swap the timeslider
  map.removeControl(time_sliders[current]);
  map.addControl(time_sliders[requested]);
  time_sliders[requested].startSlider();
};

// --------- ON LOAD --------- //

// CREATE LAYER FOR MAP TILES
var osmLayer = L.tileLayer('https://stamen-tiles-{s}.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.{ext}', {
  attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
  subdomains: 'abcd',
  minZoom: 0,
  maxZoom: 20,
  ext: 'png'
});

// ADD MAP
var map = L.map('map', {
    center: new L.LatLng(36, -78),
    zoom: 5,
    maxZoom: 18,
    layers: [osmLayer]
});

// CREATE DESTINATION LAYER
var destination_layer = L.geoJSON(destination_geojson["All"], {
  onEachFeature: onEachDestination,
  pointToLayer: function(feature, latlng) {
    return L.circleMarker(latlng, destinationMarkerOptions(feature));
  }
});

// CREATE GEOJSON LAYERS FOR CONTRACT ROUTES BY DATE
var office_layers = {};
for (var key in contracts_geojson) {
  var layer = L.geoJSON(contracts_geojson[key], {
    style: function(feature) {
      return { "weight" : 1, "color" : "black" };
    },
    onEachFeature: onEachLine
  })
  office_layers[key] = layer;
};

// ADD THE CONTRACT ROUTES TO A SLIDER CONTROL
var time_sliders = {};
for (var office in office_layers) {
  time_sliders[office] = L.control.sliderControl({
    position: "bottomleft",
    layer: office_layers[office],
    range: true,
    follow: 1,
    timeStrLength: 10,
    timeAttribute: "date",
    showAllOnStart: true,
    rezoom: true,
  });
}

var rr_1861_layer = L.geoJSON(rr_1861, {
  style: function(feature) {
    return { "weight" : 0.5, "color" : "green" }
  }
});

var rr_1870_layer = L.geoJSON(rr_1870, {
  style: function(feature) {
    return { "weight" : 0.5, "color" : "blue" }
  }
});

// start map with destination layer and 1861 railroad displayed
map.addLayer(destination_layer);
map.addLayer(rr_1861_layer);

// add layer controls to the map
//   first param: base layer (one selectable)
//   second param: opt. layers (mult selectable)
L.control.layers(
  { "1861 Railroads": rr_1861_layer, "1870 Railroads": rr_1870_layer },
  { "Popularity of Destination": destination_layer },
  { collapsed: false }
).addTo(map);

// add the fullscreen control to the map
L.control.fullscreen({
  position: 'topleft',
}).addTo(map);

// add "All" at beginning
map.addControl(time_sliders["All"]);
time_sliders["All"].startSlider();
