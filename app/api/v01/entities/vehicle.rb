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
class V01::Entities::Vehicle < Grape::Entity
  def self.entity_name
    'V01_Vehicle'
  end

  expose(:id, documentation: { type: Integer })
  expose(:ref, documentation: { type: String })
  expose(:name, documentation: { type: String })
  expose(:emission, documentation: { type: Integer })
  expose(:consumption, documentation: { type: Integer })
  expose(:capacity, documentation: { type: Integer })
  expose(:color, documentation: { type: String })
  expose(:open, documentation: { type: DateTime }) { |m| m.open && m.open.strftime('%H:%M:%S') }
  expose(:close, documentation: { type: DateTime }) { |m| m.close && m.close.strftime('%H:%M:%S') }
  expose(:tomtom_id, documentation: { type: String })
  expose(:store_start_id, documentation: { type: Integer })
  expose(:store_stop_id, documentation: { type: Integer })
  expose(:router_id, documentation: { type: Integer })
  expose(:speed_multiplicator, documentation: { type: Float })
  expose(:rest_start, documentation: { type: DateTime }) { |m| m.rest_start && m.rest_start.strftime('%H:%M:%S') }
  expose(:rest_stop, documentation: { type: DateTime }) { |m| m.rest_stop && m.rest_stop.strftime('%H:%M:%S') }
  expose(:rest_duration, documentation: { type: DateTime }) { |m| m.rest_duration && m.rest_duration.strftime('%H:%M:%S') }
  expose(:store_rest_id, documentation: { type: Integer })
end
