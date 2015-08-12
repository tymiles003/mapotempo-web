json.stores do
  json.array! @stores, partial: 'api_web/v01/stores/show', as: :store
end
