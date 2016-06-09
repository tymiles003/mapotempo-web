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

include PlanningIcalendar
include IcalendarUrlHelper

class V01::RoutesGet < Grape::API
  content_type :json, 'application/javascript'
  content_type :xml, 'application/xml'
  content_type :ics, 'text/calendar'
  default_format :json

  helpers do
    ID_DESC = 'ID or REF ref:[value]'
  end

  resource :plannings do
    params do
      requires :planning_id, type: String, desc: ID_DESC
    end
    segment '/:planning_id' do
      resource :routes do
        desc 'Fetch route.',
          nickname: 'getRoute',
          entity: V01::Entities::Route
        params do
          requires :id, type: String, desc: ID_DESC
        end
        get ':id' do
          planning_id = ParseIdsRefs.read params[:planning_id] rescue error!('Invalid planning', 400)
          route_id = ParseIdsRefs.read params[:id] rescue error!('Invalid route', 400)
          route = current_customer.plannings.where(planning_id).first!.routes.where(route_id).first!
          if params.key?(:email)
            icalendar_export_email route
            status 204
          else
            if env['api.format'] == :ics
              icalendar_route_export route
            else
              present route, with: V01::Entities::Route
            end
          end
        end
      end
    end
  end
end
