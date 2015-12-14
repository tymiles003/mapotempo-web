if @customer.job_destination_geocoding
  json.geocoding do
    json.extract! @customer.job_destination_geocoding, :id, :progress, :attempts
    json.error !!@customer.job_destination_geocoding.failed_at
    json.customer_id @customer.id
  end
else
  json.enable_references @customer.enable_references
  json.tags do
    json.array! @tags, :id, :label, :color, :icon
  end
  json.destinations do
    json.array! @destinations, partial: 'destinations/show', as: :destination
  end
end
