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
output = "#{this_dir}/../../data/contracts.js"

office_contracts = {
  "All" => []
}

# geojson object
map_contracts = {}

def get_fields(row)
  # there are a number of fields on the spreadsheet
  # that were used for calculations, this pairs it down to display / map fields
  dest_lat, dest_lng = row["destination_LatLng"] ? row["destination_LatLng"].split(/,\s?/) : [nil, nil]
  office_lat, office_lng = row["hiring_office_latlng"].split(/,\s?/)
  fields = {
    "hiringOffice" => row["hiring_office"],
    "contractDate" => row["contract_date"],
    "name" => row["label"],
    "gender" => row["gender"],
    "age" => row["age"],
    "employer" => row["employer_agent"],
    "township" => row["township"],
    "county" => row["county"],
    "state" => row["state"],
    "distanceMiles" => row["Distance/m"],
    "position" => row["position"],
    "workClass" => row["work_class"],
    "serviceMonths" => row["length_of_service_monthly"],
    "wagesMonth" => row["rate_of_pay_monthly"],
    "comments" => row["additional_comments"],
    "destinationClass" => row["distance"],
    "group" => row["group"],
    "destinationLat" => dest_lat,
    "destinationLng" => dest_lng,
    "hiringOfficeLat" => office_lat,
    "hiringOfficeLng" => office_lng,
  }
end

CSV.foreach(input, headers: true) do |row|
  # office = prepare_office_name(row["hiring_office"])
  office = row["hiring_office"].strip
  office_contracts[office] = [] if !office_contracts.has_key?(office)
  fields = get_fields(row)

  # add to office_contracts for specific office and for all
  office_contracts["All"] << fields
  office_contracts[office] << fields
end

# reorganize contract offices for eventual javascript display
offices = []
office_contracts.each do |office_key, values|
  offices << {
    "office" => office_key,
    "rows" => values.sort_by { |c| c["contractDate"]}
  }
end

File.open(output, "w") { |f| f.write("var contracts = #{offices.to_json};") }
