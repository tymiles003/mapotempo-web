json.array!(@plannings) do |planning|
  json.extract! planning, :name, :customer_id
  json.url planning_url(planning, format: :json)
end
