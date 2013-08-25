if current_user.customer.job_geocoding
  json.geocoding current_user.customer.job_geocoding.progress
else
  json.tags do
    json.array! @tags, :id, :label
  end
  json.destinations do
    json.array! @destinations, partial: 'destinations/show', as: :destination
  end
end
