class ApiV01 < Grape::API
  mount V01::Customers
  mount V01::Destinations
  mount V01::Routes
  mount V01::Tags
  mount V01::Vehicles
end
