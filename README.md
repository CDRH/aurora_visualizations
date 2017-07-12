# Aurora Visualization Demo

Using queries [here](https://gist.github.com/jduss4/88305374a3948e8bc0d109edcd580885), the csv files for destination population and contracts were created.

To (re)generate geojson files, run

```
cd csv_to_geojson

ruby destinations.rb
ruby contracts.rb
```

You should only need ruby 2.4 for those scripts, with no 3rd party gems.

Open index.html to look at a demo leaflet map with layers (top right button).
