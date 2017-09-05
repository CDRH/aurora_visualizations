def destination_label(township, county, state)
  return [township, county, state]
    .reject(&:nil?)
    .reject(&:empty?)
    .join(", ")
end

def get_latlng(latitude, longitude)
  lat = latitude.to_f
  lng = longitude.to_f
  # yes, I know I split this apart originally,
  # but that helped normalize the fields! now stick back together
  latlng = "#{lat}|#{lng}"
  return lat, lng, latlng
end
