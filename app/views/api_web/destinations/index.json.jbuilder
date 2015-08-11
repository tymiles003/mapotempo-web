json.tags do
  json.array! @tags, :id, :label, :color, :icon
end
json.destinations do
  json.array! @destinations, partial: 'api_web/destinations/show', as: :destination
end
