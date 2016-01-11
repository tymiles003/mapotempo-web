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
  TIME_2000 = Time.new(2000, 1, 1, 0, 0, 0, '+00:00').to_i

  def self.entity_name
    'V01_Route'
  end

  expose(:id, documentation: { type: Integer })
  expose(:distance, documentation: { type: Float, desc: 'Total route\'s distance.' })
  expose(:emission, documentation: { type: Float })
  expose(:vehicle_usage_id, documentation: { type: Integer })
  expose(:start, documentation: { type: DateTime }) { |m|
    if m.start
      date = (m.planning.date || Date.today).to_time + (m.start.to_i - TIME_2000)
      date.strftime('%Y-%m-%dT%H:%M:%S')
    end
  }
  expose(:end, documentation: { type: DateTime }) { |m|
    if m.end
      date = (m.planning.date || Date.today).to_time + (m.end.to_i - TIME_2000)
      date.strftime('%Y-%m-%dT%H:%M:%S')
    end
  }
  expose(:hidden, documentation: { type: 'Boolean' })
  expose(:locked, documentation: { type: 'Boolean' })
  expose(:out_of_date, documentation: { type: 'Boolean' })
  expose(:stops, using: V01::Entities::Stop, documentation: { type: V01::Entities::Stop, is_array: true })
  expose(:stop_out_of_drive_time, documentation: { type: 'Boolean' })
  expose(:stop_distance, documentation: { type: Float, desc: 'Distance between the vehicle\'s store_stop and last stop.' })
  expose(:stop_drive_time, documentation: { type: Integer, desc: 'Time in seconds between the vehicle\'s store_stop and last stop.' })
  expose(:stop_trace, documentation: { type: String, desc: 'Trace between the vehicle\'s store_stop and last stop.' })
  expose(:ref, documentation: { type: String })
  expose(:color, documentation: { type: String, desc: 'Color code with #. For instance: #FF0000' })
end
