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
require 'ai4r'

module Ai4r
  module Clusterers
    class KMeansSameSize < KMeans

      parameters_info :max_iterations => "Maximum number of iterations to " \
        "build the clusterer. By default it is uncapped.",
        :distance_function => "Custom implementation of distance function. " \
          "It must be a closure receiving two data items and return the " \
          "distance between them. By default, this algorithm uses " \
          "euclidean distance of numeric attributes to the power of 2.",
        :centroid_function => "Custom implementation to calculate the " \
          "centroid of a cluster. It must be a closure receiving an array of " \
          "data sets, and return an array of data items, representing the " \
          "centroids of for each data set. " \
          "By default, this algorithm returns a data items using the mode "\
          "or mean of each attribute on each data set.",
        :centroid_indices => "Indices of data items (indexed from 0) to be " \
          "the initial centroids.  Otherwise, the initial centroids will be " \
          "assigned randomly from the data set.",
        :on_empty => "Action to take if a cluster becomes empty, with values " \
          "'eliminate' (the default action, eliminate the empty cluster), " \
          "'terminate' (terminate with error), 'random' (relocate the " \
          "empty cluster to a random point), 'outlier' (relocate the " \
          "empty cluster to the point furthest from its centroid)."

      # Build a new clusterer, using data examples found in data_set.
      # Items will be clustered in "number_of_clusters" different
      # clusters.
      def build(data_set, number_of_clusters)
        @data_set = data_set
        @number_of_clusters = number_of_clusters
        raise ArgumentError, 'Length of centroid indices array differs from the specified number of clusters' unless @centroid_indices.empty? || @centroid_indices.length == @number_of_clusters
        raise ArgumentError, 'Invalid value for on_empty' unless @on_empty == 'eliminate' || @on_empty == 'terminate' || @on_empty == 'random' || @on_empty == 'outlier'
        @iterations = 0
        @interation_modeved = nil
        @cluster_max_size = (Float(data_set.data_items.length) / number_of_clusters).ceil

        calc_initial_centroids
        calculate_membership_clusters
        while(not stop_criteria_met)
          move_data_indices_by_dist_to_centroid
          recompute_centroids
        end

        self
      end

      # Classifies the given data item, returning the cluster index it belongs
      # to (0-based).
      def eval(data_item)
        i = -1
        get_min_index(@centroids.collect {|centroid|
          if @clusters[i += 1].data_items.length < @cluster_max_size
            distance(data_item, centroid)
          else
            Float::INFINITY
          end
        })
      end

      protected

      def stop_criteria_met
        (@interation_modeved && @interation_modeved == 0) ||
          (@max_iterations && (@max_iterations <= @iterations))
      end

      def calculate_membership_clusters
        @clusters = Array.new(@number_of_clusters) do
          Ai4r::Data::DataSet.new :data_labels => @data_set.data_labels
        end
        @cluster_indices = Array.new(@number_of_clusters) {[]}

        @data_set.data_items.each_with_index do |data_item, data_index|
          c = eval(data_item)
          @clusters[c] << data_item
          @cluster_indices[c] << data_index
        end
        manage_empty_clusters if has_empty_cluster?
      end

      def move_data_indices_by_dist_to_centroid
        h = {}
        @clusters.each_with_index do |cluster, c|
          centroid = @centroids[c]
          cluster.data_items.each_with_index do |data_item, i|
            dist_to_centroid = distance(data_item, centroid)
            gain_dist_to_centroids = @number_of_clusters.times.collect{ |j|
              dist_to_centroid - distance(data_item, @centroids[j])
            }
            data_index = @cluster_indices[c][i]
            h[data_index] = [gain_dist_to_centroids.max, gain_dist_to_centroids, c]
          end
        end

        moved = []
        waiting = Array.new(@number_of_clusters) { [] }
        # sort hash of {index => dist to centroid} by dist to centroid (ascending) and then return an array of only the indices
        h.sort_by{ |k, v| -v[0] }.each{ |k, v|
          if !moved.include? k # Not already moved and best fit in other cluster
            change = false
            c = -1
            v[1].collect{ |d| [c += 1, d] }.sort_by{ |c, d| -d }.each{ |c, d| # For each other cluster, by element gain
              # If there is an element wanting to leave the other cluster and this swap yields and improvement, swap the two elements
              oc, gain = waiting[c].collect { |oc|
                [oc, h[oc][1][v[2]]]
              }.max_by{ |oc, gain| gain }
              if gain && v[1][c] + gain > 0
                k_index = @cluster_indices[v[2]].index(k)
                oc_index = @cluster_indices[c].index(oc)
                @cluster_indices[v[2]][k_index], @cluster_indices[c][oc_index] = @cluster_indices[c][oc_index], @cluster_indices[v[2]][k_index]
                waiting[c] -= [oc]
                moved << oc
                change = true
                break
              end
              if v[1][c] > 0 && @cluster_indices[c].length < @cluster_max_size
                @cluster_indices[v[2]] -= [k]
                @cluster_indices[c] << k
                change = true
                break
              end
            }
            if !change
              waiting[v[2]] << k
            end
          end
        }
        @interation_modeved = moved.size

        # Build new clusters
        @clusters = Array.new(@number_of_clusters) do
          Ai4r::Data::DataSet.new :data_labels => @data_set.data_labels
        end

        @cluster_indices.each_with_index { |cluster_indices, c|
          cluster_indices.each{ |i| @clusters[c] << @data_set.data_items[i] }
        }

        @iterations += 1
      end
    end
  end
end
