require_relative 'helpers.rb'

class Destinations

  def initialize
    @destinations = { "All" => {} }
  end

  def add(office_key, fields)
    lat, lng, latlng = get_latlng(fields["destination_lat"], fields["destination_lng"])
    label = destination_label(fields["township"], fields["county"], fields["state"])
    if !@destinations.has_key?(office_key)
      @destinations[office_key] = {}
    end
    office = @destinations[office_key]
    if !office.has_key?(latlng)
      destination = {
        "label" => label,
        "lat" => lat,
        "lng" => lng,
        "contracts" => []
      }
      office[latlng] = destination
      # clone or else magic and doubled numbers
      @destinations["All"][latlng] = destination.clone
    end
    @destinations["All"][latlng]["contracts"] << fields
    @destinations[office_key][latlng]["contracts"] << fields
  end

  def to_geojson
    # destination wrangling
    destination_geojson = {}
    @destinations.each do |office_key, office_info|
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
    return destination_geojson
  end
end
