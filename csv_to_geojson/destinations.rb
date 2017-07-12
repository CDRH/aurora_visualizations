require 'csv'
require 'json'

destinations = []

CSV.foreach("destinations.csv", headers: true) do |row, index|
  next if row["longitude"] == "0" || row["latitude"] == "0"
  # add a point for each destination with number of contracts
  geometry = {
    "type" => "Point",
    "coordinates" => [row["longitude"].to_f, row["latitude"].to_f]
  }
  properties = row.to_hash
  properties["township"] = "Unknown" if properties["township"].nil?
  properties["county"] = "Unknown" if properties["county"].nil?
  destinations << {
    "type" => "Feature",
    "properties" => properties,
    "geometry" => geometry
  }
end

geojson = {
  "type" => "FeatureCollection",
  "features" => destinations
}

File.open("../destinations.js", "w") { |f| f.write("var destinations = #{geojson.to_json};")}
