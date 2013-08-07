json.tags do
  json.array! @tags, :id, :label
end
json.destinations do
  json.array! @destinations, partial: 'destinations/show', as: :destination
end
