require 'csv'
require 'json'

contracts = []

# TODO reenable this if you prefer having stretched out timeslider
# def getDateEnd(start, months_str)
#   split_dates = start.split("-").map(&:to_i)
#   date = DateTime.new(*split_dates)
#   months = months_str.to_f
#   # if was not a float OR if was "1000 cords"
#   # then don't add the months
#   if months == 0.0 || months == 1000.0
#     # add at least a day so that it will show up on the timeline
#     return (date+1).strftime("%Y-%m-%d")
#   else
#     puts months
#     end_date = date << -months
#     return end_date.strftime("%Y-%m-%d")
#   end
# end

def getDateEnd(start, months_str)
  # TODO ignoring the months_str for the purposes of a shortened timeslider
  split_dates = start.split("-").map(&:to_i)
  date = DateTime.new(*split_dates)
  return (date+1).strftime("%Y-%m-%d")
end

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
  properties["start"] = row["contractDate"]
  properties["end"] = getDateEnd(properties["start"], row["contractMonths"])

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

File.open("../data/contracts.js", "w") { |f| f.write("var contracts = #{geojson.to_json};") }
