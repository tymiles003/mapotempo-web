# Copyright © Mapotempo, 2015
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
#RestClient.log = $stdout


module Otp

  @cache_result = Mapotempo::Application.config.otp_cache_result
  @cache_request = Mapotempo::Application.config.otp_cache_request

  def self.compute(otp_url, router_id, from_lat, from_lng, to_lat, to_lng, datetime)
    key = [otp_url, router_id, from_lat, from_lng, to_lat, to_lng, datetime]

    result = @cache_result.read(key)
    if !result
      request = @cache_result.read(key)
      if !request
        request = RestClient.get(otp_url + '/otp/routers/' + router_id + '/plan', {
          accept: :json,
          params: {
            fromPlace: [from_lat, from_lng].join(','),
            toPlace: [to_lat, to_lng].join(','),
            # Warning, full english fashion date and time
            time: datetime.strftime('%I:%M%p'),
            date: datetime.strftime('%m-%d-%Y'),
            maxWalkDistance: 500,
            arriveBy: false,
            wheelchair: false,
            showIntermediateStops: false
          }
        })
        @cache_request.write(key, request)
      end

      data = JSON.parse(request)
      if !data['error'] && data['plan'] && data['plan']['itineraries']
        i = data['plan']['itineraries'][0]
        time = i['duration']
        distance = i['walkDistance'] || 0 # FIXME walk only
        points = i['legs'].collect{ |leg| leg['legGeometry']['points'] }.collect{ |code|
          Polylines::Decoder.decode_polyline(code)
        }.flatten(1)
        trace = Polylines::Encoder.encode_points(points, 1e6)
      else
        # TODO : throw "no route" to the UI
        distance = 1000000
        time = 60 * 60 * 12
        trace = nil
      end

      result = [distance, time, trace]
      @cache_result.write(key, result)
    end

    result
  end
end
