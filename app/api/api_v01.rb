class ApiV01 < Grape::API
  mount V01::Customers
  mount V01::Destinations
  mount V01::Plannings
  mount V01::Routes
  mount V01::Stores
  mount V01::Tags
  mount V01::Vehicles
  mount V01::Zonings
end
