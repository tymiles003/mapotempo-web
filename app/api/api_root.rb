require 'grape-swagger'

class ApiRootDef < Grape::API
  mount ApiV01
  add_swagger_documentation base_path: 'api'
end

ApiRoot = Rack::Builder.new do
  use ApiLogger
  run ApiRootDef
end
