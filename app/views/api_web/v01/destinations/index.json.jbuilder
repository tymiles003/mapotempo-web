json.tags do
  json.array! @tags, :id, :label, :color, :icon
end
json.destinations @destinations, partial: 'api_web/v01/destinations/show', as: :destination
json.stores do
  json.array! @stores
end
