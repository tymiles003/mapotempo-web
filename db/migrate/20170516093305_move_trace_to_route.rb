class MoveTraceToRoute < ActiveRecord::Migration
  def up
    add_column :routes, :geojson_tracks, :text, array: true
    add_column :routes, :geojson_points, :text, array: true
    add_column :routes, :stop_no_path, :boolean
    add_column :stops, :no_path, :boolean

    Route.find_each{ |route|
      previous_with_pos = route.vehicle_usage && route.vehicle_usage.default_store_start.try(&:position?)

      geojson_tracks = []
      route.stops.sort_by{ |s| s.route.vehicle_usage ? s.index : s.id }.each_with_index{ |stop, i|
        if stop.position? && stop.active?
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
                color: stop.route.default_color,
                drive_time: stop.drive_time,
                distance: stop.distance
              }.compact
            }.to_json
          end
        end

        stop.index = i + 1 unless stop.route.vehicle_usage
      }

      if route.stop_trace
        geojson_tracks << {
          type: 'Feature',
          geometry: {
            type: 'LineString',
            polylines: route.stop_trace,
          },
          properties: {
            color: route.default_color,
            drive_time: route.stop_drive_time,
            distance: route.stop_distance
          }.compact
        }.to_json
      end

      route.geojson_tracks = geojson_tracks unless geojson_tracks.empty?

      geojson_points = route.stops.select(&:position?).map.with_index do |stop, i|
        if stop.position?
          {
            type: 'Feature',
            geometry: {
              type: 'Point',
              coordinates: [stop.lng, stop.lat]
            },
            properties: {
              index: stop.index,
              active: stop.active,
              color: stop.is_a?(StopVisit) ? stop.default_color : nil,
              icon: stop.icon,
              icon_size: stop.icon_size
            }
          }.to_json
        end
      end.compact

      route.geojson_points = geojson_points unless geojson_points.empty?

      route.save!
    }

    change_column :stops, :index, :integer, null: false
    remove_column :stops, :trace
    remove_column :routes, :stop_trace
  end

  def down
    add_column :stops, :trace, :text
    add_column :routes, :stop_trace, :text
    change_column :stops, :index, :integer, null: true

    Route.find_each{ |route|
      next unless route.geojson_tracks
      geojson_track_stop = nil

      if route.geojson_tracks
        geojson_tracks = route.geojson_tracks.map{ |s| JSON.parse(s) }
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

        route.stop_trace = geojson_track_stop['geometry']['polylines'] if geojson_track_stop
      end

      route.save!
    }

    remove_column :routes, :geojson_tracks
    remove_column :routes, :geojson_points
    remove_column :routes, :stop_no_path
    remove_column :stops, :no_path
  end
end
