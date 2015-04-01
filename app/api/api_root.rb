require 'grape-swagger'

class ApiRootDef < Grape::API
  mount ApiV01
  documentation_class = add_swagger_documentation base_path: 'api', hide_documentation_path: true, info: {
    title: Mapotempo::Application.config.product_name + ' API',
    description: 'API access require an api_key.',
    contact: Mapotempo::Application.config.product_contact
  }
end

ApiRoot = Rack::Builder.new do
  use ApiLogger
  run ApiRootDef
end
