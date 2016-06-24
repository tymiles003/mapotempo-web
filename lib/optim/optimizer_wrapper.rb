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
require 'rest_client'

class OptimizerWrapper

  attr_accessor :cache, :url, :api_key

  def initialize(cache, url, api_key)
    @cache, @url, @api_key = cache, url, api_key
  end

  def optimize(matrix, dimension, services, stores, rests, optimize_time, soft_upper_bound, cluster_threshold)
    key = Digest::MD5.hexdigest(Marshal.dump([matrix, dimension, services, stores, rests, optimize_time, soft_upper_bound, cluster_threshold]))

    result = @cache.read(key)
    if !result
      # TODO not compute too big matrix before seding it here
      is_loop = if stores.include?(:start) && stores.include?(:stop) && matrix[0] == matrix[-1] && matrix.collect(&:first) == matrix.collect(&:last)
        matrix = matrix[0..-2].collect{ |r| r[0..-2] }
      end

      vrp = {
        matrices: {
          time: matrix.collect{ |row| row.collect(&:first) },
          distance: matrix.collect{ |row| row.collect(&:last) }
        },
        points: matrix.size.times.collect{ |i| {
          id: "p#{i}",
          matrix_index: i
        }},
        services: services.each_with_index.collect{ |service, index| {
          id: "s#{index + 1}",
          activity: {
            point_id: "p#{index + 1}",
            timewindows: [
              (service[:start1] || service[:end1]) && {
                start: service[:start1],
                end: service[:end1]
              },
              (service[:start2] || service[:end2]) && {
                start: service[:start2],
                end: service[:end2]
              },
            ].compact,
            duration: service[:duration]
          }
        }},
        rests: rests.each_with_index.collect{ |rest, index| {
          id: "r#{index + services.size + 1 + 1}",
          timewindows: [{
            start: rest[:start],
            end: rest[:end]
          }],
          duration: rest[:duration]
        }},
        vehicles: [{
          id: 'v0',
          start_point_id: stores.include?(:start) ? 'p0' : nil,
          end_point_id: stores.include?(:stop) ? (is_loop ? 'p0' : "p#{matrix.size - 1}") : nil,
          cost_fixed: 0,
          cost_distance_multiplier: dimension == 'distance' ? 1 : 0,
          cost_time_multiplier: dimension == 'time' ? 1 : 0,
          cost_waiting_time_multiplier: dimension == 'time' ? 1 : 0,
          cost_late_multiplier: dimension == 'time' ? soft_upper_bound : 0,
          rests: rests.each_with_index.collect{ |rest, index| "r#{index + services.size + 1 + 1}" }
        }],
        resolution: {
          preprocessing_cluster_threshold: cluster_threshold,
          preprocessing_prefer_short_segment: true,
          duration: optimize_time,
         }
      }

      resource_vrp = RestClient::Resource.new(@url + '/vrp/submit.json')
      json = resource_vrp.post({api_key: @api_key, vrp: vrp}.to_json, content_type: :json, accept: :json)

      result = nil
      while json
        result = JSON.parse(json)
        if result['job']['status'] == 'completed'
          @cache.write(key, json && String.new(json)) # String.new workaround waiting for RestClient 2.0
          break
        elsif ['queued', 'working'].include?(result['job']['status'])
          sleep(2)
          job_id = result['job']['id']
          json = RestClient.get(@url + "/vrp/job/#{job_id}.json", params: {api_key: @api_key})
        else
          raise RuntimeError.new(result['job']['avancement'] || 'Optimizer return unknow error')
        end
      end
    else
      result = JSON.parse(result)
    end

    result['solution']['routes'][0]['activities'].collect{ |activity|
      if activity.key?('service_id')
        activity['service_id'][1..-1].to_i
      elsif activity.key?('rest_id')
        activity['rest_id'][1..-1].to_i
      else
        activity['point_id'][1..-1].to_i
      end
    }
  end
end
