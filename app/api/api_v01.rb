class ApiV01 < Grape::API
  mount V01::Customers
end
