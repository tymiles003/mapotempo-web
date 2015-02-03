if @customer.job_geocoding
  json.geocoding do
    json.extract! @customer.job_geocoding, :progress, :attempts
    json.error !!@customer.job_geocoding.failed_at
  end
else
  json.tags do
    json.array! @tags, :id, :label, :color, :icon
  end
  json.destinations do
    json.array! @destinations, partial: 'destinations/show', as: :destination
  end
end
