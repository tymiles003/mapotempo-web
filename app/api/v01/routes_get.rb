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
        desc 'Fetch planning\'s routes.',
          nickname: 'getRoutes',
          is_array: true,
          entity: V01::Entities::Route
        params do
          optional :ids, type: Array[String], desc: 'Select returned routes by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
        end
        get do
          planning_id = ParseIdsRefs.read(params[:planning_id])
          routes = if params.key?(:ids)
            current_customer.plannings.where(planning_id).first!.routes.select{ |route|
              params[:ids].any?{ |s| ParseIdsRefs.match(s, route) }
            }
          else
            current_customer.plannings.where(planning_id).first!.routes.load
          end
          present routes, with: V01::Entities::Route
        end

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
            route_calendar_email route
            status 204
          else
            if env['api.format'] == :ics
              route_calendar(route).to_ical
            else
              present route, with: V01::Entities::Route
            end
          end
        end
      end
    end
  end
end
