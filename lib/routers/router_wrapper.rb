# Copyright © Mapotempo, 2016
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
require 'rest_client'
#RestClient.log = $stdout

class RouterError < StandardError ; end

module Routers
  class RouterWrapper

    attr_accessor :cache_request, :cache_result, :api_key

    def initialize(cache_request, cache_result, api_key)
      @cache_request, @cache_result = cache_request, cache_result
      @api_key = api_key
    end

    def compute(url, mode, from_lat, from_lng, to_lat, to_lng, speed_multiplicator = nil, dimension = nil)
      key = ['c', url, mode, dimension, from_lat, from_lng, to_lat, to_lng, speed_multiplicator]

      request = @cache_request.read(key)
      if !request
        params = {
          api_key: @api_key,
          mode: mode,
          dimension: dimension,
          speed_multiplicator: speed_multiplicator == 1 ? nil : speed_multiplicator,
          loc: [from_lat, from_lng, to_lat, to_lng].join(',')
        }.compact
        resource = RestClient::Resource.new(url + '/0.1/route.json', timeout: nil)
        request = resource.get(params: params) { |response, request, result, &block|
          case response.code
          when 200
            response
          when 204 # UnreachablePointError
            ''
          when 417 # OutOfSupportedAreaError
            ''
          else
            # response.return!(request, result, &block)
            raise RouterError.new(result)
          end
        }

        @cache_request.write(key, request && String.new(request)) # String.new workaround waiting for RestClient 2.0
      end

      if request == ''
        [nil, nil, nil]
      else
        data = JSON.parse(request)
        if data && data.key?('features') && data['features'].size > 0
          feature = data['features'][0]
          distance = feature['properties']['router']['total_distance'] if feature['properties'] && feature['properties']['router']
          time = feature['properties']['router']['total_time'] if feature['properties'] && feature['properties']['router']
          trace = feature['geometry']['polylines'] if feature['geometry']
          [distance, time, trace]
        else
          [nil, nil, nil]
        end
      end
    end

    def matrix(url, mode, row, column, speed_multiplicator = nil, dimension = nil)
      key = ['m', url, mode, row, column, speed_multiplicator]

      request = @cache_request.read(key)
      if !request
        params = {
          api_key: @api_key,
          mode: mode,
          dimension: dimension,
          src: row.flatten.join(','),
          dst: row != column ? column.flatten.join(',') : nil,
          speed_multiplicator: speed_multiplicator == 1 ? nil : speed_multiplicator
        }.compact
        resource = RestClient::Resource.new(url + '/0.1/matrix.json', timeout: nil)
        request = resource.get(params: params) { |response, request, result, &block|
          case response.code
          when 200
            response
          when 417
            ''
          else
            response.return!(request, result, &block)
          end
        }

        @cache_request.write(key, request && String.new(request)) # String.new workaround waiting for RestClient 2.0
      end

      if request == ''
        Array.new(row.size) { Array.new(column.size, 2147483647) }
      else
        data = JSON.parse(request)
        if data.key?('matrix')
          data['matrix'].collect{ |r|
            r.collect{ |rr|
              rr || 2147483647
            }
          }
        end
      end
    end

    def isoline(url, mode, lat, lng, size, speed_multiplicator = nil, dimension = nil)
      key = ['i', url, mode, lat, lng, size, speed_multiplicator]

      request = @cache_request.read(key)
      if !request
        params = {
          api_key: @api_key,
          mode: mode,
          dimension: dimension,
          loc: [lat, lng].join(','),
          size: size,
          speed_multiplicator: speed_multiplicator == 1 ? nil : speed_multiplicator
        }.compact
        resource = RestClient::Resource.new(url + '/0.1/isoline.json', timeout: nil)
        request = resource.get(params: params) { |response, request, result, &block|
          case response.code
          when 200
            response
          when 417
            ''
          else
            response.return!(request, result, &block)
          end
        }

        @cache_request.write(key, request && String.new(request)) # String.new workaround waiting for RestClient 2.0
      end

      if request == ''
        nil
      else
        data = JSON.parse(request)
        if data['features']
          # MultiPolygon not supported by Leaflet.Draw
          data['features'].collect! { |feat|
            if feat['geometry']['type'] == 'LineString'
              feat['geometry']['type'] = 'Polygon'
              feat['geometry']['coordinates'] = [feat['geometry']['coordinates']]
            end
            feat
          }
          data.to_json
        else
          nil
        end
      end
    end
  end
end
