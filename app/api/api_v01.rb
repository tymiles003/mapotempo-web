class ApiV01 < Grape::API
  mount V01::Customers
  mount V01::Destinations
end
