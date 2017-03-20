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
class V01::Entities::VehicleUsageSet < Grape::Entity
  def self.entity_name
    'V01_VehicleUsageSet'
  end

  expose(:id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:open, documentation: { types: [Integer, DateTime] }) { |m| m.open_time }
  expose(:close, documentation: { types: [Integer, DateTime] }) { |m| m.close_time }
  expose(:store_start_id, documentation: { type: Integer })
  expose(:store_stop_id, documentation: { type: Integer })
  expose(:service_time_start, documentation: { types: [Integer, DateTime] }) { |m| m.service_time_start_time }
  expose(:service_time_end, documentation: { types: [Integer, DateTime] }) { |m| m.service_time_end }
  expose(:rest_start, documentation: { types: [Integer, DateTime] }) { |m| m.rest_start_time }
  expose(:rest_stop, documentation: { types: [Integer, DateTime] }) { |m| m.rest_stop_time }
  expose(:rest_duration, documentation: { types: [Integer, DateTime] }) { |m| m.rest_duration_time }
  expose(:store_rest_id, documentation: { type: Integer })
end
