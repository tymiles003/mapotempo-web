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
class ApiLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    payload = {
      remote_addr:    env['REMOTE_ADDR'],
      request_method: env['REQUEST_METHOD'],
      request_path:   env['PATH_INFO'],
      request_query:  env['QUERY_STRING'],
      x_organization: env['HTTP_X_ORGANIZATION']
    }

    ActiveSupport::Notifications.instrument 'grape.request', payload do
      @app.call(env).tap do |response|
        if env['api.endpoint']
          payload[:params] = (env['api.endpoint'].params.nil? && env['api.endpoint'].params.to_hash) || {}
          payload[:params].delete('route_info')
          payload[:params].delete('format')
        end
        payload[:response_status] = response[0]
      end
    end
  end
end
