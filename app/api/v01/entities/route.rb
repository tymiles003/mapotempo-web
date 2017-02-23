# Copyright © Mapotempo, 2014-2015
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
class V01::Entities::Route < Grape::Entity
  def self.entity_name
    'V01_Route'
  end

  expose(:id, documentation: { type: Integer })
  expose(:ref, documentation: { type: String })
  expose(:distance, documentation: { type: Float, desc: 'Total route\'s distance.' })
  expose(:emission, documentation: { type: Float })
  expose(:vehicle_usage_id, documentation: { type: Integer })
  expose(:start, documentation: { type: DateTime }) { |m|
    (m.planning.date || Time.zone.today).beginning_of_day + m.start if m.start
  }
  expose(:end, documentation: { type: DateTime }) { |m|
    (m.planning.date || Time.zone.today).beginning_of_day + m.end if m.end
  }
  expose(:hidden, documentation: { type: 'Boolean' })
  expose(:locked, documentation: { type: 'Boolean' })
  expose(:out_of_date, documentation: { type: 'Boolean' })
  expose(:stops, using: V01::Entities::Stop, documentation: { type: V01::Entities::Stop, is_array: true })
  expose(:stop_out_of_drive_time, documentation: { type: 'Boolean' })
  expose(:stop_distance, documentation: { type: Float, desc: 'Distance between the vehicle\'s store_stop and last stop.' })
  expose(:stop_drive_time, documentation: { type: Integer, desc: 'Time in seconds between the vehicle\'s store_stop and last stop.' })
  expose(:color, documentation: { type: String, desc: 'Color code with #. For instance: #FF0000' })
  expose(:updated_at, documentation: { type: DateTime, desc: 'Last Updated At'})
  expose(:last_sent_to, documentation: { type: String, desc: 'Type GPS Device of Last Sent'})
  expose(:last_sent_at, documentation: { type: DateTime, desc: 'Last Time Sent To External GPS Device'})
  expose(:optimized_at, documentation: { type: DateTime, desc: 'Last optimized at'})
  expose(:geojson, documentation: { type: String, desc: 'Geojson string of track and stops of the route. Default empty, set parameter geojson=true to get this extra content.' }) { |m, options|
    options[:geojson] != :false && m.to_geojson(true, options[:geojson] == :polyline) || nil
  }
end

class V01::Entities::RouteStatus < Grape::Entity
  def self.entity_name
    'V01_RouteStatus'
  end

  expose(:id, documentation: { type: Integer })
  expose(:vehicle_usage_id, documentation: { type: Integer })
  expose(:last_sent_to, documentation: { type: String, desc: 'Type GPS Device of Last Sent'})
  expose(:last_sent_at, documentation: { type: DateTime, desc: 'Last Time Sent To External GPS Device'})
  expose(:stops, using: V01::Entities::StopStatus, documentation: { type: V01::Entities::StopStatus, is_array: true })
end
