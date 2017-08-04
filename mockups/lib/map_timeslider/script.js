// Relies upon https://github.com/skeate/Leaflet.timeline

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

function onEachLine(feature, layer) {
  var prop = feature.properties;
  var html = "<strong>" + prop.workerName + "</strong>";
  html += "<ul>";
    html += "<li>Worker Age: " + prop.contractWorkerAge + "</li>";
    html += "<li>Worker Gender: " + prop.workerGender + "</li>";
    html += "<li>Work Type: " + prop.contractWorkClass + "</li>";
    html += "<li>Contract Date: " + prop.contractDate + "</li>";
    html += "<li>Contract Employer: " + prop.contractEmployerAgent + "</li>";
    html += "<li>Wages: " + prop.contractPay + "</li>";
    html += "<li>Period: " + prop.contractMonths + "</li>";
  html += "</ul>"
  layer.bindTooltip(html);
};

// TIME SLIDER
var timeline = L.timeline(contracts, {
  style: function(data){
    return {
      stroke: 1,
      color: "red",
      fillOpacity: 0.5
    }
  },
  waitToUpdateMap: true,
  onEachFeature: onEachLine
});
var timelineControl = L.timelineSliderControl({
  formatOutput: function(date) {
    return new Date(date).toLocaleDateString();
  },
  enableKeyboardControls: true,
});
timeline.addTo(map);
timelineControl.addTo(map);
timelineControl.addTimelines(timeline);

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
var destinations = L.geoJSON(destinations, {
  onEachFeature: onEachDestination,
  pointToLayer: function(feature, latlng) {
    return L.circleMarker(latlng, destinationMarkerOptions(feature));
  }
});

// start map with destination layer displayed
map.addLayer(destinations);

// add layer controls to the map
//   first param: base layer (one selectable)
//   second param: opt. layers (mult selectable)
L.control.layers({}, { "Popularity of Destination" : destinations }, { collapsed: false }).addTo(map);
