require 'csv'
require 'json'

##### contracts generation #####
#
# 2017 August
# Jessica Dussault
#
# Purpose:
#   This script takes a CSV with individual's contract information
#   and manipulates it into the following JSON (sorta) objects
#   - contracts by office sorted by date
#   - contracts for all offices sorted by date
#   - geojson consolidating office to destination BY DAY

this_dir = File.dirname(__FILE__)
input = "#{this_dir}/../csv/contracts.csv"
output_table = "#{this_dir}/../../data/contracts.js"
output_geojson = "#{this_dir}/../../data/geojson.js"

office_contracts = {
  "All" => []
}
@office_geojson = {}

def add_geojson(office, fields)
  # skip if there is no lat / lng
  if fields["destination_lng"].to_f != 0.0 && fields["destination_lat"].to_f != 0.0
    # create some geojson
    if !@office_geojson.has_key?(office)
      @office_geojson[office] = []
    end
    @office_geojson[office] << {
      "type" => "Feature",
      "properties" => fields,
      "geometry" => {
        "type" => "LineString",
        "coordinates" => [
          [fields["office_lng"].to_f, fields["office_lat"].to_f],
          [fields["destination_lng"].to_f, fields["destination_lat"].to_f]
        ]
      }
    }
  end
end

def get_fields(row)
  # there are a number of fields on the spreadsheet
  # that were used for calculations, this pairs it down to display / map fields
  dest_lat, dest_lng = row["destination_LatLng"] ? row["destination_LatLng"].split(/,\s?/) : [nil, nil]
  office_lat, office_lng = row["hiring_office_latlng"].split(/,\s?/)
  fields = {
    "hiring_office" => row["hiring_office"],
    "contract_date" => row["contract_date"],
    "name" => row["label"],
    "gender" => row["gender"],
    "age" => row["age"],
    "employer" => row["employer_agent"],
    "township" => row["township"],
    "county" => row["county"],
    "state" => row["state"],
    "distance_miles" => row["Distance/m"],
    "position" => row["position"],
    "work_class" => row["work_class"],
    "service_months" => row["length_of_service_monthly"],
    "wages_month" => row["rate_of_pay_monthly"],
    "comments" => row["additional_comments"],
    "destination_class" => row["distance"],
    "group" => row["group"],
    "destination_lat" => dest_lat,
    "destination_lng" => dest_lng,
    "office_lat" => office_lat,
    "office_lng" => office_lng,
  }
end

CSV.foreach(input, headers: true) do |row|
  office = row["hiring_office"].strip
  office_contracts[office] = [] if !office_contracts.has_key?(office)
  fields = get_fields(row)

  # add to office_contracts for specific office and for all
  office_contracts["All"] << fields
  office_contracts[office] << fields

  next if office == "All"
  add_geojson(office, fields)
end

# TABLE display reorganization
offices = []
office_contracts.each do |office_key, values|
  offices << {
    "office" => office_key,
    "rows" => values.sort_by { |c| c["contractDate"]}
  }
end

geojson = {
  "All" => {
    "type" => "FeatureCollection",
    "features" => []
  }
}
@office_geojson.each do |office_key, values|
  geojson[office_key] = {
    "type" => "FeatureCollection",
    "features" => values
  }
  geojson["All"]["features"] = values

end

File.open(output_table, "w") { |f| f.write("var contracts = #{offices.to_json};") }
File.open(output_geojson, "w") { |f| f.write("var geojson = #{geojson.to_json};") }
