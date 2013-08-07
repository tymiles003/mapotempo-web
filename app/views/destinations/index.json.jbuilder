json.array!(@destinations) do |destination|
  json.extract! destination, :name, :street, :postalcode, :city, :lat, :lng, :quantity, :open, :close, :user_id
  json.url destination_url(destination, format: :json)
end
