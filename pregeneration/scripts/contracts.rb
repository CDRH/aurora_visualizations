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
#   - contracts by office sorted by date (including all offices)
#   - geojson consolidating office to destination BY DAY (including all offices)
#   - geojson with destination popularity calculations
#   - breakdown of gender of individuals contracted at each office
#   - breakdown of occupation contracted by each office

this_dir = File.dirname(__FILE__)
input = "#{this_dir}/../csv/contracts.csv"
output_table = "#{this_dir}/../../data/contracts.js"
output_contracts_geojson = "#{this_dir}/../../data/contracts_geojson.js"
output_destination_geojson = "#{this_dir}/../../data/destination_geojson.js"
output_dclass = "#{this_dir}/../../data/destination_class.js"
output_gender = "#{this_dir}/../../data/gender.js"
output_occupation = "#{this_dir}/../../data/occupation.js"

@combined_contract_routes = { "All" => {} }
@destination_popularity = { "All" => {} }
@office_contracts = { "All" => [] }
@destination_class = {
  "All" => {
    "Same County" => 0,
    "Within State or Nearby" => 0,
    "North or South Border" => 0,
    "North" => 0,
    "Internal South" => 0,
    "Internal or Deep South" => 0,
    "Unknown" => 0
  }
}
@gender = { "All" => { "female" => 0, "male" => 0, "unknown" => 0 } }
@occupation = { "All" =>
  { "Agricultural" => 0, "Domestic" => 0, "Laborer" => 0, "Other" => 0, "Unspecified" => 0 }
}

def add_destination(office_key, latlng, label)
  lat, lng = latlng.split("|")
  if !@destination_popularity.has_key?(office_key)
    @destination_popularity[office_key] = {}
  end
  office = @destination_popularity[office_key]
  if !office.has_key?(latlng)
    destination = {
      "label" => label,
      "count" => 0,
      "lat" => lat,
      "lng" => lng
    }
    office[latlng] = destination
    # clone or else magic and doubled numbers
    @destination_popularity["All"][latlng] = destination.clone
  end
  office[latlng]["count"] += 1
  @destination_popularity["All"][latlng]["count"] += 1
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

  lat = fields["destination_lat"].to_f
  lng = fields["destination_lng"].to_f
  # yes, I know I split this apart originally, but that helped normalize the fields!
  latlng = "#{lat}|#{lng}"
  # TODO probably this should be not happening in this method
  add_destination(office, latlng, destination)

  if !hiring_office[date].has_key?(latlng)
    feature = {
      "type" => "Feature",
      "properties" => {
        "contracts" => [],
        "date" => date,
        # "time" => time,
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
    hiring_office[date][latlng] = feature
    all[date][latlng] = feature.clone
  end
  hiring_office[date][latlng]["properties"]["contracts"] << fields
  @combined_contract_routes["All"][date][latlng]["properties"]["contracts"] << fields
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

def tally_destination_class(office, destination)
  dclass = case destination
    when "C"
      "Same County"
    when "P"
      "Within State or Nearby"
    when "BN"
      "North or South Border"
    when "N"
      "North"
    when "I"
      "Internal South"
    when "I/DS"
      "Internal or Deep South"
    else
      "Unknown"
    end
  if !@destination_class.has_key?(office)
    @destination_class[office] = {
      "Same County" => 0,
      "Within State or Nearby" => 0,
      "North or South Border" => 0,
      "North" => 0,
      "Internal South" => 0,
      "Internal or Deep South" => 0,
      "Unknown" => 0
    }
  end
  @destination_class[office][dclass] += 1
  @destination_class["All"][dclass] += 1
end

def tally_gender(office, gender)
  gender = (gender == "female" || gender == "male") ? gender : "unknown"
  if !@gender.has_key?(office)
    @gender[office] = {
      "female" => 0,
      "male" => 0,
      "unknown" => 0
    }
  end
  @gender[office][gender] += 1
  @gender["All"][gender] += 1
end

def tally_occupation(office, occupation)
  class_type = case occupation
    when "Agricultural", "Domestic", "Laborer", "Other"
      occupation
    else
      "Unspecified"
    end
  if !@occupation.has_key?(office)
    @occupation[office] = {
      "Agricultural" => 0,
      "Domestic" => 0,
      "Laborer" => 0,
      "Other" => 0,
      "Unspecified" => 0
    }
  end
  @occupation[office][class_type] += 1
  @occupation["All"][class_type] += 1
end



CSV.foreach(input, headers: true) do |row|
  office = row["hiring_office"].strip
  @office_contracts[office] = [] if !@office_contracts.has_key?(office)
  fields = get_fields(row)

  # add to office_contracts for specific office and for all
  @office_contracts["All"] << fields
  @office_contracts[office] << fields
  tally_destination_class(office, fields["destination_class"])
  tally_gender(office, fields["gender"])
  tally_occupation(office, fields["work_class"])

  # skip all the mapping related steps if there is no specific destination
  next if fields["destination_lng"].to_f == 0.0 || fields["destination_lat"].to_f == 0.0
  combine_contract_routes(office, fields)
end

# TABLE display organization
offices = []
@office_contracts.each do |office_key, values|
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
    contracts_geojson[office_key]["features"] += features
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
        "count" => destination["count"]
      },
      "geometry" => {
        "type" => "Point",
        "coordinates" => [destination["lng"], destination["lat"]]
      }
    }
    destination_geojson[office_key]["features"] << geojson_obj
  end
end

# format destination type
dest_class_json = {}
@destination_class.each do |office, office_info|
  dest_class_json[office] = []
  office_info.each do |dest, number|
    dest_class_json[office] << { "property" => dest, "contracts" => number }
  end
end

# format gender
gender_json = {}
@gender.each do |office, office_info|
  gender_json[office] = []
  office_info.each do |gender, number|
    gender_json[office] << { "property" => gender, "contracts" => number }
  end
end

# format occupation
occupation_json = {}
@occupation.each do |office, office_info|
  occupation_json[office] = []
  office_info.each do |occupation, number|
    occupation_json[office] << { "property" => occupation.downcase, "contracts" => number }
  end
end

File.open(output_table, "w") { |f| f.write("var contracts = #{offices.to_json};") }
File.open(output_contracts_geojson, "w") { |f| f.write("var contracts_geojson = #{contracts_geojson.to_json};") }
File.open(output_destination_geojson, "w") { |f| f.write("var destination_geojson = #{destination_geojson.to_json};") }
File.open(output_dclass, "w") { |f| f.write("var destination_class = #{dest_class_json.to_json};") }
File.open(output_gender, "w") { |f| f.write("var gender = #{gender_json.to_json};") }
File.open(output_occupation, "w") { |f| f.write("var occupation = #{occupation_json.to_json};") }
