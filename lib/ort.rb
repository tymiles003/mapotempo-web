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
  @time_threshold = Mapotempo::Application.config.optimize_cluster_size

  def self.optimize(optimize_time, soft_upper_bound, capacity, matrix, time_window, time_threshold)
    time_threshold ||= @time_threshold
    key = [soft_upper_bound, capacity, matrix.hash, time_window.hash, time_threshold]

    cluster(matrix, time_window, time_threshold) { |matrix, time_window|
      result = @cache.read(key)
      if !result
        data = {
          capacity: capacity,
          matrix: matrix,
          time_window: time_window,
          optimize_time: optimize_time,
          soft_upper_bound: soft_upper_bound
        }.to_json
        resource = RestClient::Resource.new(@url, timeout: nil)
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
    matrix, time_window, zip_key = zip_cluster(matrix, time_window, time_threshold)
    result = yield(matrix, time_window)
    unzip_cluster(result, zip_key, original_matrix)
  end

  def self.zip_cluster(matrix, time_window, time_threshold)
    data_set = DataSet.new(data_items: (1..(matrix.length - 2)).collect{ |i| [i] })
    c = CompleteLinkageMaxDistance.new
    c.distance_function = lambda do |a, b|
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
    result.size.times.collect{ |ii|
      i = result[ii]
      if i == 0
        ret << 0
      elsif i == zip_key.length + 1
        ret << original_matrix.length - 1
      elsif zip_key[i - 1].data_items.length > 1
        sub = zip_key[i - 1].data_items.collect{ |i| i[0] }
        start = result[ii - 1] - 1 >= 0 ? zip_key[result[ii - 1] - 1].data_items[0][0] : 0
        stop = result[ii + 1] - 1 < zip_key.length ? zip_key[result[ii + 1] - 1].data_items[0][0] : original_matrix.length - 1
        sub = [start] + sub + [stop]
        sub_size = sub.length
        min_order = if sub_size <= 5
          sub.permutation(sub_size).collect{ |p|
            last = ret[-1]
            s = p.sum { |s|
              a, last = last, s
              original_matrix[a][s]
            }
            [s, p]
          }.min{ |a, b| a[0] <=> b[0] }[1]
        else
          sim_annealing = SimAnnealing::SimAnnealing.new
          sim_annealing.start = start
          sim_annealing.stop = stop
          sim_annealing.matrix = original_matrix
          r = sim_annealing.search(sub,  (1..[sub_size, 8].min).reduce(1, :*), 100000.0, 0.999)[:vector] # Yes, compute factorial
          r.collect{ |i| sub[i] }
        end

        index = min_order.index(start)
        if min_order[(index + 1) % sub_size] == stop
          min_order = min_order.reverse
          index = sub_size - 1 - index
        end
        min_order = index == 0 ? min_order : min_order[index..-1] + min_order[0..index-1] # shift to replace start at beginning
        min_order = min_order[1..-2] # remove start and stop
        ret += min_order
      else
        ret << zip_key[i - 1].data_items[0][0]
      end
    }.flatten
    ret
  end
end

module SimAnnealing
  class SimAnnealing
    attr_accessor :start, :stop, :matrix

    def euc_2d(c1, c2)
      if (c1 == start || c1 == stop) && (c2 == start || c2 == stop)
        0
      else
        matrix[c1][c2][0]
      end
    end
  end
end
