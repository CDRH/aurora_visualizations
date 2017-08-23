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

# mappings for fields
@mapping_dest_class = {
  "C" => "Within County",
  "P" => "Proximate County",
  "BN" => "North or South Border",
  "N" => "North",
  "I" => "Internal South",
  "I/DS" => "Internal or Deep South",
  "U" => "Unknown"
}

@mapping_gender = {
  "female" => "Female",
  "male" => "Male",
  "unknown" => "Unknown"
}

@mapping_group = {
  "I" => "Individual",
  "G" => "Group",
  "F" => "Family",
  "U" => "Unknown"
}

@mapping_occupation = [
  "Domestic",
  "Agricultural",
  "Other",
  "Laborer",
  "Unknown"
]

@combined_contract_routes = { "All" => {} }
@destination_popularity = { "All" => {} }
@office_contracts = { "All" => [] }

# bumping this above the counter holders below
def zeroed_hash(mapping)
  if mapping.class == Hash
    mapping.map{ |k, v| [v, 0] }.to_h
  elsif mapping.class == Array
    mapping.map { |v| [v, 0] }.to_h
  else
    raise "Not sure how to process mapping of class #{mapping.class}"
  end
end

@destination_class = { "All" => zeroed_hash(@mapping_dest_class) }
@gender = { "All" => zeroed_hash(@mapping_gender) }
@group = { "All" => zeroed_hash(@mapping_group) }
@occupation = { "All" => zeroed_hash(@mapping_occupation) }

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

def chart_formatter(variable)
  chart_data = {}
  variable.each do |office, office_info|
    chart_data[office] = []
    office_info.each do |property, number|
      chart_data[office] << { "property" => property, "contracts" => number }
    end
  end
  return chart_data
end

def code_to_label(mapping, code)
  if mapping.class == Hash
    return mapping[code] || "Unknown"
  elsif mapping.class == Array
    return mapping.include?(code) ? code : "Unknown"
  else
    raise "Not sure how to process mapping of class #{mapping.class}"
  end
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
    "gender" => code_to_label(@mapping_gender, row["gender"]),
    "age" => row["age"] || "",
    "employer" => row["employer_agent"] || "",
    "township" => row["township"] || "",
    "county" => row["county"] || "",
    "state" => row["state"] || "",
    "distance_miles" => row["Distance/m"] || "",
    "position" => row["position"] || "",
    "work_class" => code_to_label(@mapping_occupation, row["work_class"]),
    "service_months" => row["length_of_service_monthly"] || "",
    "wages_months" => row["rate_of_pay_monthly"] || "",
    "destination_class" => code_to_label(@mapping_dest_class, row["distance"]),
    "group" => code_to_label(@mapping_group, row["group"]),
    "destination_lat" => dest_lat,
    "destination_lng" => dest_lng,
    "office_lat" => office_lat,
    "office_lng" => office_lng,
  }
end

def tally_field(office, counter, value, mapping)
  if !counter.has_key?(office)
    counter[office] = zeroed_hash(mapping)
  end
  counter[office][value] += 1
  counter["All"][value] += 1
end

CSV.foreach(input, headers: true) do |row|
  office = row["hiring_office"].strip
  @office_contracts[office] = [] if !@office_contracts.has_key?(office)
  fields = get_fields(row)

  # add to office_contracts for specific office and for all
  @office_contracts["All"] << fields.clone
  @office_contracts[office] << fields.clone
  tally_field(office, @destination_class, fields["destination_class"], @mapping_dest_class)
  tally_field(office, @gender, fields["gender"], @mapping_gender)
  tally_field(office, @group, fields["group"], @mapping_group)
  tally_field(office, @occupation, fields["work_class"], @mapping_occupation)

  # skip all the mapping related steps if there is no specific destination
  next if fields["destination_lng"].to_f == 0.0 || fields["destination_lat"].to_f == 0.0
  combine_contract_routes(office, fields.clone)
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

dest_class_json = chart_formatter(@destination_class)
group_json = chart_formatter(@group)
gender_json = chart_formatter(@gender)
occupation_json = chart_formatter(@occupation)

File.open(output_table, "w") { |f| f.write("var contracts = #{offices.to_json};") }
File.open(output_contracts_geojson, "w") { |f| f.write("var contracts_geojson = #{contracts_geojson.to_json};") }
File.open(output_destination_geojson, "w") { |f| f.write("var destination_geojson = #{destination_geojson.to_json};") }
File.open(output_dclass, "w") { |f| f.write("var destination_class = #{dest_class_json.to_json};") }
File.open(output_gender, "w") { |f| f.write("var gender = #{gender_json.to_json};") }
File.open(output_group, "w") { |f| f.write("var group = #{group_json.to_json};") }
File.open(output_occupation, "w") { |f| f.write("var occupation = #{occupation_json.to_json};") }
