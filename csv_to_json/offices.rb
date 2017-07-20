require 'csv'
require 'json'

offices = {}

CSV.foreach("contracts.csv", headers: true) do |row|
  # unless if people have a better idea, I'm skipping anything with a "0"
  # for destination because otherwise it maps people as traveling to the
  # middle of the Atlantic Ocean
  office = row["hiringName"].downcase.gsub(" ", "_")
  if !offices.has_key?(office)
    offices[office] = []
  end

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
  offices[office] << {
    "type" => "Feature",
    "properties" => properties,
    "geometry" => geometry
  }
end

offices.each do |office_name, values|
  geojson = {
    "type" => "FeatureCollection",
    "features" => values
  }
  File.open("../data/offices/#{office_name}.js", "w") do |f|
    f.write("var #{office_name} = #{geojson.to_json};")
  end
end
