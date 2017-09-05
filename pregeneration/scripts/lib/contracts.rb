require_relative 'helpers.rb'

class Contracts

  def initialize
    @combined_routes = { "All" => {} }
    @by_office = { "All" => [] }
  end

  def add_route(office, fields)
    # assumes that no empty destination lat/lng passed through
    # if multiple contracts following a route happen on the same DAY
    # then combine the data for display purposes
    # check hiring office -> date -> lat+lng
    if !@combined_routes.has_key?(office)
      @combined_routes[office] = {}
    end
    hiring_office = @combined_routes[office]
    all = @combined_routes["All"]
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
    @combined_routes["All"][date][latlng]["properties"]["contracts"] << fields.clone
  end

  def add_to_table(office, fields)
    @by_office[office] = [] if !@by_office.has_key?(office)
    @by_office[office] << fields
    @by_office["All"] << fields
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

  def to_geojson
    contracts_geojson = {
      "All" => {
        "type" => "FeatureCollection",
        "features" => []
      }
    }
    # no doubt there's a better way to flatten this rather than nested iterations
    # but since this isn't going to run every time I'm not gonna worry about it now
    @combined_routes.each do |office_key, office_info|
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
    return contracts_geojson
  end

  def to_table_json
    offices = []
    @by_office.each do |office_key, values|
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
    return offices
  end

end
