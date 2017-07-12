require 'csv'
require 'json'

contracts = []

CSV.foreach("contracts.csv", headers: true) do |row|
  # unless if people have a better idea, I'm skipping anything with a "0"
  # for destination because otherwise it maps people as traveling to the
  # middle of the Atlantic Ocean

  next if row["destLong"] == "0" || row["destLat"] == "0"
  # add a line for each contract and add descriptive info
  geometry = {
    "type" => "LineString",
    "coordinates" => [
      [row["hiringLong"].to_f, row["hiringLat"].to_f],
      [row["destLong"].to_f, row["destLat"].to_f]
    ]
  }
  properties = row.to_hash
  contracts << {
    "type" => "Feature",
    "properties" => properties,
    "geometry" => geometry
  }
end

geojson = {
  "type" => "FeatureCollection",
  "features" => contracts
}

File.open("../contracts.js", "w") { |f| f.write("var contracts = #{geojson.to_json};") }
