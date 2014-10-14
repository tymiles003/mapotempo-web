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
require 'json'

module Trace

  @cache_request = Mapotempo::Application.config.trace_cache_request
  @cache_result = Mapotempo::Application.config.trace_cache_result

  def self.compute(osrm_url, from_lat, from_lng, to_lat, to_lng)
    key = [osrm_url, from_lat, from_lng, to_lat, to_lng]

    result = @cache_result.read(key)
    if !result
      request = @cache_request.read(key)
      if !request
        begin
          uri = URI(url = "#{osrm_url}/viaroute")
          uri.query = "loc=#{from_lat},#{from_lng}&loc=#{to_lat},#{to_lng}&alt=false&output=json"
          Rails.logger.info "get #{uri}"
          res = Net::HTTP.get_response(uri)
          if res.is_a?(Net::HTTPSuccess)
            request = JSON.parse(res.body)
            @cache_request.write(key, request)
          else
            raise http.message
          end
        rescue OpenSSL::SSL::SSLError
          raise "Unable to communicate over SSL"
        rescue Errno::ECONNREFUSED
          raise "Connection was refused"
        rescue Errno::ETIMEDOUT
          raise "Timed out connecting"
        rescue Errno::EHOSTDOWN
          raise "The host not responding to requests"
        rescue Errno::EHOSTUNREACH
          raise "Possible network issue communicating"
        rescue SocketError
          raise "Couldn't make sense of the host destination"
        rescue JSON::ParserError
          raise "The host returned a non-JSON response"
        end
      end

      if request["route_summary"]
        distance = request["route_summary"]["total_distance"]
        time = request["route_summary"]["total_time"]
        trace = request["route_geometry"]
      else
        # TODO : throw "no route" to the UI
        distance = 1000000
        time = 60*60*12
        trace = nil
      end

      result = [distance, time, trace]
      @cache_result.write(key, result)
    end

    result
  end

  def self.matrix(osrm_url, vector)
    i = -1
    vector.map!{ |a| a << i+=1 }
    vector.sort!{ |a,b|
      a[0] != b[0] ? a[0] <=> b[0] : a[1] <=> b[1]
    }

    key = [osrm_url, vector.map{ |v| v[0..1] }.hash]

    result = @cache_result.read(key)
    if !result
      request = @cache_request.read(key)
      if !request
        begin
          uri = URI(url = "#{osrm_url}/table")
          uri.query = vector.map{ |a| "loc=#{a[0]},#{a[1]}" }.join('&')
          Rails.logger.info "get #{uri}"
          res = Net::HTTP.get_response(uri)
          if res.is_a?(Net::HTTPSuccess)
            request = JSON.parse(res.body)
            @cache_request.write(key, request)
          else
            raise http.message
          end
        rescue OpenSSL::SSL::SSLError
          raise "Unable to communicate over SSL"
        rescue Errno::ECONNREFUSED
          raise "Connection was refused"
        rescue Errno::ETIMEDOUT
          raise "Timed out connecting"
        rescue Errno::EHOSTDOWN
          raise "The host not responding to requests"
        rescue Errno::EHOSTUNREACH
          raise "Possible network issue communicating"
        rescue SocketError
          raise "Couldn't make sense of the host destination"
        rescue JSON::ParserError
          raise "The host returned a non-JSON response"
        end
      end

      result = request["distance_table"]
      @cache_result.write(key, result)
    end

    # Restore original order
    size = vector.size
    column = []
    size.times{ |i|
      line = []
      size.times{ |j|
        line[vector[j][2]] = (result[i][j]/10).round # TODO >= 2147483647 ? nil : (result[i][j]/10).round
      }
      column[vector[i][2]] = line
    }

    column
  end
end
