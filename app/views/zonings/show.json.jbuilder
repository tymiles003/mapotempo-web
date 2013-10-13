json.vehicles @vehicles do |vehicle|
  json.extract! vehicle, :id, :name, :color
end
json.zoning @zoning.zones do |zone|
  json.extract! zone, :polygon
  json.vehicles @vehicles do |vehicle|
    json.extract! vehicle, :id, :name
    if zone.vehicles.include? vehicle
      json.selected true
    end
  end
end
