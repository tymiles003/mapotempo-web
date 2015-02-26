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
require 'json'
require 'polylines'

#RestClient.log = $stdout


module Here

  @cache_result = Mapotempo::Application.config.here_cache_result

  def self.compute(from_lat, from_lng, to_lat, to_lng)
    key = [from_lat, from_lng, to_lat, to_lng]

    result = @cache_result.read(key)
    if !result
      request = self.get('7.2/calculateroute', {
        waypoint0: "geo!#{from_lat},#{from_lng}",
        waypoint1: "geo!#{to_lat},#{to_lng}",
        mode: "fastest;truck;traffic:disabled",
        alternatives: 0,
        resolution: 1,
        representation: "display",
        routeAttributes: "summary,shape",
        truckType: "truck",
        #limitedWeight: # Truck routing only, vehicle weight including trailers and shipped goods, in tons. 
        #weightPerAxle: # Truck routing only, vehicle weight per axle in tons.
        #height: # Truck routing only, vehicle height in meters.
        #width: # Truck routing only, vehicle width in meters.
        #length: # Truck routing only, vehicle length in meters.
        #tunnelCategory : # Specifies the tunnel category to restrict certain route links. The route will pass only through tunnels of a less strict category. Enum [B | C | D | E] 
      })

      r = request['response']['route'][0]
      s = r['summary']
      result = [s['distance'], s['trafficTime'], Polylines::Encoder.encode_points(r['shape'].collect{ |p|
        p.split(',').collect(&:to_f)
      }, 1e6)]
      @cache_result.write(key, result)
    end

    result
  end

  def self.matrix(vector, &block)
    raise "More than 100x100 matrix, not possible with Here" if vector.size > 100

    key = [vector.map{ |v| v[0..1] }.hash]

    result = @cache_result.read(key)
    if !result

      # From Here "Matrix Routing API Developer's Guide"
      # Recommendations for Splitting Matrixes
      # The best way to split a matrix request is to split it into parts with only few start positions and many
      # destinations. The number of the start positions should be between 3 and 15, depending on the size
      # of the area covered by the matrix. The matrices should be split into requests sufficiently small to
      # ensure a response time of 30 seconds each. The number of the destinations in one request is limited
      # to 100.

      # Request should not contain more than 15 starts per request
      # 500 to get response before 30 seconds timeout
      split_size = [15, (1000 / vector.size).round].min

      result = Array.new(vector.size) { Array.new(vector.size) }

      commons_param = {
        mode: "fastest;truck;traffic:disabled",
        #limitedWeight: # Truck routing only, vehicle weight including trailers and shipped goods, in tons.
        #weightPerAxle: # Truck routing only, vehicle weight per axle in tons.
        #height: # Truck routing only, vehicle height in meters.
        #width: # Truck routing only, vehicle width in meters.
        #length: # Truck routing only, vehicle length in meters.
      }
      0.upto(vector.size - 1).each{ |i|
        commons_param["destination#{i}"] = "#{vector[i][0].round(5)},#{vector[i][1].round(5)}"
      }

      total = vector.size**2
      column_start = 0
      while column_start <= vector.size do
        request = @cache_result.read([key, column_start, split_size])
        if !request
          param = commons_param.dup
          column_start.upto([column_start + split_size - 1, vector.size - 1].min).each{ |i|
            param["start#{i - column_start}"] = "#{vector[i][0].round(5)},#{vector[i][1].round(5)}"
          }
          request = self.get('6.2/calculatematrix', param)
          @cache_result.write([key, column_start, split_size], request)
        end

        request['Response']['MatrixEntry'].each{ |e|
          s = e['Route']['Summary']
          result[column_start + e['StartIndex']][e['DestinationIndex']] = [s['Distance'].round, s['BaseTime'].round]
        }

        column_start = column_start + split_size
        block.call(vector.size * split_size, total) if block
      end

      @cache_result.write(key, result)
    end

    result
  end

  private
    @cache_request = Mapotempo::Application.config.here_cache_request

    @api_url = Mapotempo::Application.config.here_api_url
    @api_app_id = Mapotempo::Application.config.here_api_app_id
    @api_app_code = Mapotempo::Application.config.here_api_app_code

    def self.get(object, params = {})
      url = "#{@api_url}/#{object.to_s}.json"
      params = {app_id: @api_app_id, app_code: @api_app_code}.merge(params)

      key = [url, params].hash
      request = @cache_request.read(key)
      if !request
        begin
          response = RestClient.get(url, {params: params})
        rescue => e
          Rails.logger.info e.response
          raise e
        end
        request = JSON.parse(response)
        @cache_request.write(key, request)
      end

      request
    end
end
