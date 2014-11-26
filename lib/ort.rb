# Copyright © Mapotempo, 2013-2014
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
require 'rest_client'

module Ort

  @cache = Mapotempo::Application.config.optimize_cache
  @url = Mapotempo::Application.config.optimize_url
  @optimize_time = Mapotempo::Application.config.optimize_time

  def self.optimize(capacity, matrix, time_window)
    key = [capacity, matrix.hash, time_window.hash]

    result = @cache.read(key)
    if !result
      data = {
        capacity: capacity,
        matrix: matrix,
        time_window: time_window,
        optimize_time: @optimize_time
      }.to_json
      resource = RestClient::Resource.new(@url, timeout: -1)
      result = resource.post({data: data}, {content_type: :json, accept: :json})
      @cache.write(key, result)
    end

    jdata = JSON.parse(result)
    jdata['optim']
  end
end
