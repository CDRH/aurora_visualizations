# Aurora Visualization Demo

This is a single page view with visualizations of data collected from seven Freedmen's Bureaus' labor contracts at the Civil War's conclusion.

- Alexandria (1866)
- Camp Nelson (1865)
- Chattanooga (1866)
- Louisville (1866 - 1867)
- Memphis (1865)
- Petersburg (1865)
- Wisewell Barracks (1866 - 1867)

This site pregenerates the JSON used to power the map, charts, and table views from a CSV in order to accomplish the goal of zero database integration and "dropability" of the site into multiple environments.

- [Map](#map)
- [Charts and Table](#charts-and-table)
- [Other Components](#other-components)
- [Regenerating the Data](#regenerating-the-data)

## Map

The map is powered by [Leaflet](http://leafletjs.com/).  Its base layer is pulling from [Stamen Design's Toner Lite](http://maps.stamen.com/toner-lite/#12/37.7706/-122.3782) and therefore also [OpenStreetMap](http://openstreetmap.org/).

The map also utilizes a slider for date range selection, [LeafletSlider](https://github.com/dwilhelm89/LeafletSlider), from a fork's branch [removeAllMarkers](https://github.com/jduss4/LeafletSlider/tree/removeAllMarkers).  The slider requires [jQuery UI](https://jqueryui.com/).

Finally, the map's fullscreen ability is provided by [leaflet.fullscreen](https://github.com/brunob/leaflet.fullscreen).

## Charts and Table

The charts and table are built with [d3.js](https://d3js.org/).  Fortunately, despite d3 being unfamiliar territory, the following tutorials and answers were helpful in the construction of these features.

- [D3 Dynamic Pie Chart Demo](https://codepen.io/interactivematt/pen/ZGWYOO) (majority of code's construction)
- [D3 Dynamic Array of Tables](https://bl.ocks.org/boeric/e16ad218bc241dfd2d6e)
- [Doughnut Transition demo](http://ninjapixel.io/StackOverflow/doughnutTransition.html)
- [Simple Pie Chart](http://bl.ocks.org/enjalot/1203641)
- [Stack Overflow changing labels](https://stackoverflow.com/a/21844448/4154134)

## Other Components

The layout of this site uses [Bootstrap](http://getbootstrap.com/) and [jQuery](https://jquery.com/).

## Regenerating the Data

Install [ruby 2.4.1](https://www.ruby-lang.org/en/downloads/).  The script is running off of data at `pregeneration/csv/contracts.csv`.  Make changes as needed, then run:

```
ruby pregeneration/scripts/contracts.rb
```

This will update the files in the data repository.  You should see changes immediately upon refreshing your browser.
