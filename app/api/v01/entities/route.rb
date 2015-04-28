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
  expose(:distance, documentation: { type: Float })
  expose(:emission, documentation: { type: Float })
  expose(:vehicle_id, documentation: { type: Integer })
  expose(:start, documentation: { type: DateTime } ) { |m| m.start && m.start.strftime('%H:%M:%S') }
  expose(:end, documentation: { type: DateTime } ) { |m| m.end && m.end.strftime('%H:%M:%S') }
  expose(:hidden, documentation: { type: 'Boolean' })
  expose(:locked, documentation: { type: 'Boolean' })
  expose(:out_of_date, documentation: { type: 'Boolean' })
  expose(:stops, using: V01::Entities::Stop, documentation: { type: V01::Entities::Stop, is_array: true })
  expose(:stop_trace, documentation: { type: String })
  expose(:stop_out_of_drive_time, documentation: { type: 'Boolean' })
  expose(:stop_distance, documentation: { type: Float })
  expose(:ref, documentation: { type: String })
end
