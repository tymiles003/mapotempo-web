# Copyright © Mapotempo, 2013-2015
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
require 'ai4r'
include Ai4r::Data
require 'complete_linkage_max_distance'
include Ai4r::Clusterers

require 'rest_client'

module Ort

  @cache = Mapotempo::Application.config.optimize_cache
  @url = Mapotempo::Application.config.optimize_url
  @optimize_time = Mapotempo::Application.config.optimize_time

  def self.optimize(capacity, matrix, time_window, time_threshold)
    time_threshold ||= 5
    key = [capacity, matrix.hash, time_window.hash, time_threshold]

    self.cluster(matrix, time_window, time_threshold) { |matrix, time_window|
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
    }
  end

  private

  def self.cluster(matrix, time_window, time_threshold)
    original_matrix = matrix
    matrix, time_window, zip_key = self.zip_cluster(matrix, time_window, time_threshold)
    result = yield(matrix, time_window)
    self.unzip_cluster(result, zip_key, original_matrix)
  end

  def self.zip_cluster(matrix, time_window, time_threshold)
    data_set = DataSet.new(:data_items => (1..(matrix.length - 2)).collect{ |i| [i] })
    c = CompleteLinkageMaxDistance.new
    c.distance_function = lambda do |a,b|
      time_window[a[0]] == time_window[b[0]] ? matrix[a[0]][b[0]][0] : Float::INFINITY
    end
    clusterer = c.build(data_set, time_threshold)

    new_size = clusterer.clusters.size

    # Build replacement list
    ptr = Array.new(new_size + 2)
    ptr[0] = 0
    ptr[new_size + 1] = matrix.size - 1
    new_time_window = Array.new(new_size + 1)
    new_time_window[0] = time_window[0]

    clusterer.clusters.each_with_index do |cluster, i|
      oi = cluster.data_items[0][0]
      ptr[i + 1] = oi
      new_time_window[i + 1] = time_window[oi]
    end

    # Fill new matrix
    new_matrix = Array.new(new_size + 2) { Array.new(new_size + 2) }
    (new_size + 2).times{ |i|
      (new_size + 2).times{ |j|
        new_matrix[i][j] = matrix[ptr[i]][ptr[j]]
      }
    }

    [new_matrix, new_time_window, clusterer.clusters]
  end

  def self.unzip_cluster(result, zip_key, original_matrix)
    ret = []
    result.collect{ |i|
      if i == 0
        ret << 0
      elsif i == zip_key.length + 1
        ret << original_matrix.length - 1
      elsif zip_key[i - 1].data_items.length > 1
        sub = zip_key[i - 1].data_items.collect{ |i| i[0] }
        sub_size = sub.length
        sub_matrix = Array.new(sub_size) { Array.new(sub_size) }
        sub_size.times.each{ |i|
          sub_size.times.each{ |j|
            sub_matrix[i][j] = original_matrix[sub[i]][sub[j]]
          }
        }
        # TODO not compute permutation on larger dataset
        min_order = sub.permutation(sub_size).collect{ |p|
          last = ret[-1]
          s = p.sum { |s|
            a, last = last, s
            original_matrix[a][s]
          }
          [s, p]
        }.min{ |a, b| a[0] <=> b[0] }[1]
        ret += min_order
      else
        ret << zip_key[i - 1].data_items[0][0]
      end
    }.flatten
    ret
  end
end
