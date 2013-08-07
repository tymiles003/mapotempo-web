json.array!(@plannings) do |planning|
  json.extract! planning, :name, :user_id
  json.url planning_url(planning, format: :json)
end
