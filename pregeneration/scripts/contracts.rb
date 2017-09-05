require 'csv'
require 'json'
require_relative 'lib/contracts.rb'
require_relative 'lib/pieChart.rb'
require_relative 'lib/destinations.rb'

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

# make a contracts instance
contracts = Contracts.new

# make destinations instance
destinations = Destinations.new

# make pie charts for four categories
destination_class = PieChart.new("destination_class")
gender = PieChart.new("gender")
group = PieChart.new("group")
occupation = PieChart.new("occupation")

# iterate through the spreadsheet and handle each row
CSV.foreach(input, headers: true) do |row|
  office = row["hiring_office"].strip
  fields = get_fields(row)

  # add the fields to the table collection
  contracts.add_to_table(office, fields.clone)

  # add row's info to pie chart tallies
  destination_class.tally_field(office, fields["destination_class"])
  gender.tally_field(office, fields["gender"])
  group.tally_field(office, fields["group"])
  occupation.tally_field(office, fields["work_class"])

  # skip all the mapping related steps if there is no specific destination
  next if fields["destination_lng"].to_f == 0.0 || fields["destination_lat"].to_f == 0.0
  contracts.add_route(office, fields)
  destinations.add(office, fields.clone)
end

# create geojson and json for map and table
contracts_geojson = contracts.to_geojson
destination_geojson = destinations.to_geojson
offices = contracts.to_table_json

# create json for pie charts
dest_class_json = destination_class.chart_formatter
group_json = group.chart_formatter
gender_json = gender.chart_formatter
occupation_json = occupation.chart_formatter

# write to files
File.open("#{output_dir}/contracts.js", "w") { |f| f.write("var contracts = #{offices.to_json};") }
File.open("#{output_dir}/contracts_geojson.js", "w") { |f| f.write("var contracts_geojson = #{contracts_geojson.to_json};") }
File.open("#{output_dir}/destination_geojson.js", "w") { |f| f.write("var destination_geojson = #{destination_geojson.to_json};") }
File.open("#{output_dir}/destination_class.js", "w") { |f| f.write("var destination_class = #{dest_class_json.to_json};") }
File.open("#{output_dir}/gender.js", "w") { |f| f.write("var gender = #{gender_json.to_json};") }
File.open("#{output_dir}/group.js", "w") { |f| f.write("var group = #{group_json.to_json};") }
File.open("#{output_dir}/occupation.js", "w") { |f| f.write("var occupation = #{occupation_json.to_json};") }
