json.id zoning.id
json.zones zoning.zones do |zone|
  json.extract! zone, :polygon
  json.vehicles do
    json.array!(zone.vehicles) do |vehicle|
      json.extract! vehicle, :id
    end
  end
end
