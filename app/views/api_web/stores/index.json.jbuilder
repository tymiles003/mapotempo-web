json.stores do
  json.array! @stores, partial: 'api_web/stores/show', as: :store
end
