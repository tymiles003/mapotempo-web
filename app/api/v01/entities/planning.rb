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
class V01::Entities::Planning < Grape::Entity
  def self.entity_name
    'V01_Planning'
  end

  expose(:id, documentation: { type: Integer })
  expose(:name, documentation: { type: String })
  expose(:ref, documentation: { type: String })
  expose(:date, documentation: { type: Date })
  expose(:vehicle_usage_set_id, documentation: { type: Integer })
  expose(:zoning_id, documentation: { type: Integer, desc: 'DEPRECATED. Use zoning_ids instead.' }) { |p|
    p.zonings.first.id if p.zonings.size == 1
  }
  expose(:zoning_ids, documentation: { type: Integer, is_array: true })
  expose(:zoning_out_of_date, documentation: { type: 'Boolean' })
  expose(:out_of_date, documentation: { type: 'Boolean' })
  expose(:route_ids, documentation: { type: Integer, is_array: true }) { |m| m.routes.collect(&:id) } # Workaround bug with fetch join stops
  expose(:tag_ids, documentation: { type: Integer, is_array: true })
  expose(:updated_at, documentation: { type: DateTime, desc: 'Last Updated At'})
end
