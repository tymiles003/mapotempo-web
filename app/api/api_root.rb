require 'grape-swagger'

class ApiRoot < Grape::API
  mount ApiV01
  add_swagger_documentation base_path: 'api'
end
