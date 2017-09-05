require 'csv'
require 'json'
require_relative 'lib/pieChart.rb'

##### contracts generation #####
#
# 2017 August
# Jessica Dussault
#
# Purpose:
#   This script takes a CSV with individual's contract information
#   and manipulates it into the following JSON (sorta) objects
#   - contracts by office sorted by date (including all offices)
#   - geojson consolidating office to destination BY DAY (including all offices)
#   - geojson with destination popularity calculations
#   - breakdown of gender, group type, occupation class, and destination class per office

this_dir = File.dirname(__FILE__)
input = "#{this_dir}/../csv/contracts.csv"
output_dir = "#{this_dir}/../../data"
output_table = "#{output_dir}/contracts.js"
output_contracts_geojson = "#{output_dir}/contracts_geojson.js"
output_destination_geojson = "#{output_dir}/destination_geojson.js"
output_dclass = "#{output_dir}/destination_class.js"
output_group = "#{output_dir}/group.js"
output_gender = "#{output_dir}/gender.js"
output_occupation = "#{output_dir}/occupation.js"

@combined_contract_routes = { "All" => {} }
@destination_popularity = { "All" => {} }
@office_contracts = { "All" => [] }


def add_destination(office_key, fields)
  lat, lng, latlng = get_latlng(fields["destination_lat"], fields["destination_lng"])
  label = destination_label(fields["township"], fields["county"], fields["state"])
  if !@destination_popularity.has_key?(office_key)
    @destination_popularity[office_key] = {}
  end
  office = @destination_popularity[office_key]
  if !office.has_key?(latlng)
    destination = {
      "label" => label,
      "lat" => lat,
      "lng" => lng,
      "contracts" => []
    }
    office[latlng] = destination
    # clone or else magic and doubled numbers
    @destination_popularity["All"][latlng] = destination.clone
  end
  @destination_popularity["All"][latlng]["contracts"] << fields
  @destination_popularity[office_key][latlng]["contracts"] << fields
end

def combine_contract_routes(office, fields)
  # assumes that no empty destination lat/lng passed through
  # if multiple contracts following a route happen on the same DAY
  # then combine the data for display purposes
  # check hiring office -> date -> lat+lng
  if !@combined_contract_routes.has_key?(office)
    @combined_contract_routes[office] = {}
  end
  hiring_office = @combined_contract_routes[office]
  all = @combined_contract_routes["All"]
  date = fields["contract_date"]
  if !hiring_office.has_key?(date)
    hiring_office[date] = {}
    all[date] = {}
  end

  destination = destination_label(fields["township"], fields["county"], fields["state"])
  lat, lng, latlng = get_latlng(fields["destination_lat"], fields["destination_lng"])

  if !hiring_office[date].has_key?(latlng)
    feature_params = [office, date, destination, fields, lat, lng]
    office_feature = geojson_feature(*feature_params)
    all_feature = geojson_feature(*feature_params)
    hiring_office[date][latlng] = office_feature
    all[date][latlng] = all_feature
  end
  hiring_office[date][latlng]["properties"]["contracts"] << fields.clone
  @combined_contract_routes["All"][date][latlng]["properties"]["contracts"] << fields.clone
end

def geojson_feature(office, date, destination, fields, lat, lng)
  {
    "type" => "Feature",
    "properties" => {
      "contracts" => [],
      "date" => date,
      "office" => office,
      "destination" => destination
    },
    "geometry" => {
      "type" => "LineString",
      "coordinates" => [
        [fields["office_lng"].to_f, fields["office_lat"].to_f],
        [lng, lat]
      ]
    }
  }
end

def destination_label(township, county, state)
  return [township, county, state]
    .reject(&:nil?)
    .reject(&:empty?)
    .join(", ")
end

def get_fields(row)
  # there are a number of fields on the spreadsheet
  # that were used for calculations, this pairs it down to display / map fields
  dest_lat, dest_lng = row["destination_LatLng"] ? row["destination_LatLng"].split(/,\s?/) : [nil, nil]
  office_lat, office_lng = row["hiring_office_latlng"].split(/,\s?/)
  return {
    "hiring_office" => row["hiring_office"],
    "contract_date" => row["contract_date"] || "",
    "name" => row["label"] || "",
    "gender" => PieChart.code_to_label("gender", row["gender"]),
    "age" => row["age"] || "",
    "employer" => row["employer_agent"] || "",
    "township" => row["township"] || "",
    "county" => row["county"] || "",
    "state" => row["state"] || "",
    "distance_miles" => row["Distance/m"] || "",
    "position" => row["position"] || "",
    "work_class" => PieChart.code_to_label("occupation", row["work_class"]),
    "service_months" => row["length_of_service_monthly"] || "",
    "wages_months" => row["rate_of_pay_monthly"] || "",
    "destination_class" => PieChart.code_to_label("destination_class", row["distance"]),
    "group" => PieChart.code_to_label("group", row["group"]),
    "destination_lat" => dest_lat,
    "destination_lng" => dest_lng,
    "office_lat" => office_lat,
    "office_lng" => office_lng,
  }
end

def get_latlng(latitude, longitude)
  lat = latitude.to_f
  lng = longitude.to_f
  # yes, I know I split this apart originally,
  # but that helped normalize the fields! now stick back together
  latlng = "#{lat}|#{lng}"
  return lat, lng, latlng
end

# make pie charts for four categories
destination_class = PieChart.new("destination_class")
gender = PieChart.new("gender")
group = PieChart.new("group")
occupation = PieChart.new("occupation")

CSV.foreach(input, headers: true) do |row|
  office = row["hiring_office"].strip
  @office_contracts[office] = [] if !@office_contracts.has_key?(office)
  fields = get_fields(row)

  # add to office_contracts for specific office and for all
  @office_contracts["All"] << fields.clone
  @office_contracts[office] << fields.clone

  # add contract's info to pie chart tallies
  destination_class.tally_field(office, fields["destination_class"])
  gender.tally_field(office, fields["gender"])
  group.tally_field(office, fields["group"])
  occupation.tally_field(office, fields["work_class"])

  # skip all the mapping related steps if there is no specific destination
  next if fields["destination_lng"].to_f == 0.0 || fields["destination_lat"].to_f == 0.0
  combine_contract_routes(office, fields.clone)
  add_destination(office, fields.clone)
end

# TABLE display organization
offices = []
@office_contracts.each do |office_key, values|
  # remove a few columns we don't want in the display
  values.map do |row|
    row.delete("destination_lat")
    row.delete("destination_lng")
    row.delete("office_lat")
    row.delete("office_lng")
    row
  end

  offices << {
    "office" => office_key,
    "rows" => values.sort_by { |c| c["contract_date"]}
  }
end

# GEOJSON organization
contracts_geojson = {
  "All" => {
    "type" => "FeatureCollection",
    "features" => []
  }
}
# no doubt there's a better way to flatten this rather than nested iterations
# but since this isn't going to run every time I'm not gonna worry about it now
@combined_contract_routes.each do |office_key, office_info|
  contracts_geojson[office_key] = {
    "type" => "FeatureCollection",
    "features" => []
  }
  # sort by the date key and make back into a hash
  office_info = Hash[office_info.sort]
  office_info.each do |date, date_info|
    # kill the latlong keys by going straight to the values
    features = date_info.values
    contracts_geojson[office_key]["features"] += features.clone
  end
end

# destination wrangling
destination_geojson = {}
@destination_popularity.each do |office_key, office_info|
  destination_geojson[office_key] = {
    "type" => "FeatureCollection",
    "features" => []
  }
  destinations = office_info.values
  destinations.each do |destination|
    geojson_obj = {
      "type" => "Feature",
      "properties" => {
        "label" => destination["label"],
        "count" => destination["contracts"].length,
        "contracts" => destination["contracts"]
      },
      "geometry" => {
        "type" => "Point",
        "coordinates" => [destination["lng"], destination["lat"]]
      }
    }
    destination_geojson[office_key]["features"] << geojson_obj
  end
end

dest_class_json = destination_class.chart_formatter
group_json = group.chart_formatter
gender_json = gender.chart_formatter
occupation_json = occupation.chart_formatter

File.open(output_table, "w") { |f| f.write("var contracts = #{offices.to_json};") }
File.open(output_contracts_geojson, "w") { |f| f.write("var contracts_geojson = #{contracts_geojson.to_json};") }
File.open(output_destination_geojson, "w") { |f| f.write("var destination_geojson = #{destination_geojson.to_json};") }
File.open(output_dclass, "w") { |f| f.write("var destination_class = #{dest_class_json.to_json};") }
File.open(output_gender, "w") { |f| f.write("var gender = #{gender_json.to_json};") }
File.open(output_group, "w") { |f| f.write("var group = #{group_json.to_json};") }
File.open(output_occupation, "w") { |f| f.write("var occupation = #{occupation_json.to_json};") }
