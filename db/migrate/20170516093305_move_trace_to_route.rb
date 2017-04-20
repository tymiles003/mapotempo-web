class MoveTraceToRoute < ActiveRecord::Migration
  def up
    add_column :routes, :geojson_tracks, :text
    add_column :routes, :geojson_points, :text
    add_column :routes, :stop_no_path, :boolean
    add_column :stops, :no_path, :boolean

    Route.find_each{ |route|
      previous_with_pos = route.vehicle_usage && route.vehicle_usage.default_store_start.try(&:position?)

      geojson_tracks = []
      route.stops.select(&:position?).select(&:active).each{ |stop|
        stop.no_path |= stop.position? && stop.active && route.vehicle_usage && !stop.trace && previous_with_pos
        previous_with_pos = stop if stop.position?

        if stop.trace
          geojson_tracks << {
            type: 'Feature',
            geometry: {
              type: 'LineString',
              polylines: stop.trace,
            },
            properties: {
              route_id: stop.route_id,
              color: stop.route.default_color,
              stop_id: stop.id,
              drive_time: stop.drive_time,
              distance: stop.distance
            }.compact
          }.to_json
        end
      }

      if route.stop_trace
        geojson_tracks << {
          type: 'Feature',
          geometry: {
            type: 'LineString',
            polylines: route.stop_trace,
          },
          properties: {
            route_id: route.id,
            color: route.default_color,
            drive_time: route.stop_drive_time,
            distance: route.stop_distance
          }.compact
        }.to_json
      end

      if !geojson_tracks.empty?
        route.geojson_tracks = geojson_tracks.join(',')
      end

      multi_points_coordinates = []
      multi_points_properties = []
      route.stops.select(&:position?).each{ |stop|
        multi_points_coordinates << [stop.lat, stop.lng]
        multi_points_properties << {
          stop_id: stop.id,
          color: stop.color,
          icon: stop.icon,
          icon_size: stop.icon_size
        }.compact
      }

      if !multi_points_coordinates.empty?
        route.geojson_points = {
          type: 'Feature',
          geometry: {
            type: 'MultiPoint',
            polylines: Polylines::Encoder.encode_points(multi_points_coordinates, 1e6),
          },
          properties: {
            planning_id: route.planning_id,
            route_id: route.id,
            color: route.default_color,
            points: multi_points_properties
          }.compact
        }.to_json
      end

      route.save!
    }

    remove_column :stops, :trace
    remove_column :routes, :stop_trace
  end

  def down
    add_column :stops, :trace, :text
    add_column :routes, :stop_trace, :text

    Route.find_each{ |route|
      next if !route.geojson_tracks

      if route.geojson_tracks
        geojson_tracks = JSON.parse('[' + route.geojson_tracks + ']')
        if route.vehicle_usage && route.vehicle_usage.default_store_stop
          geojson_track_stop = geojson_tracks[-1]
          geojson_tracks = geojson_tracks[0..-2]
        end

        if geojson_tracks
          route.stops.select(&:position?).select(&:active).reject(&:no_path).zip(geojson_tracks).each{ |stop, coordinates|
            if stop && coordinates
              stop.trace = coordinates['geometry']['polylines']
            end
          }
        end

        if geojson_track_stop
          route.stop_trace = geojson_track_stop['geometry']['polylines']
        end
      end

      route.save!
    }

    remove_column :routes, :geojson_tracks
    remove_column :routes, :geojson_points
    remove_column :routes, :stop_no_path
    remove_column :stops, :no_path
  end
end
