json.tags do
  json.array! @tags, :id, :label, :color, :icon
end
json.destinations do
  json.array! @destinations, partial: 'api_web/v01/destinations/show', as: :destination
end
json.stores do
  json.array! @stores
end
