# Copyright © Mapotempo, 2014-2015
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
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
