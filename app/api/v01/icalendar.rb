# Copyright © Mapotempo, 2014-2016
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

include PlanningExport
include PlanningIcalendar
include IcalendarUrlHelper

class V01::Icalendar < Grape::API

  ID_DESC = 'ID or REF ref:[value]'

  content_type :ics, 'text/calendar'
  format :ics
  default_format :ics

  resource :plannings do
    desc 'Planning: Export Calendar ICS'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id/icalendar' do
      planning_id = ParseIdsRefs.read params[:id] rescue error!('Invalid IDs', 400)
      planning = current_customer.plannings.where(planning_id).first!
      if params[:email].to_i == 1
        planning.routes.joins(vehicle_usage: [:vehicle]).each do |route|
          next if !route.vehicle_usage.vehicle.contact_email
          icalendar_export_email planning, route
        end
        status 204
      else
        icalendar_planning_export planning
      end
    end

    desc 'Route: Export Calendar ICS'
    params do
      requires :planning_id, type: String, desc: ID_DESC
      requires :id, type: String, desc: ID_DESC
    end
    get ':planning_id/routes/:id/icalendar' do
      planning_id = ParseIdsRefs.read params[:planning_id] rescue error!('Invalid IDs', 400)
      route_id = ParseIdsRefs.read params[:id] rescue error!('Invalid IDs', 400)
      planning = current_customer.plannings.where(planning_id).first!
      route = planning.routes.where(route_id).first!
      if params[:email].to_i == 1
        icalendar_export_email planning, route
        status 204
      else
        icalendar_route_export planning, route
      end
    end
  end

end
