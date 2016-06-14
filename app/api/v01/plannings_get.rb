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

class V01::PlanningsGet < Grape::API
  content_type :json, 'application/javascript'
  content_type :xml, 'application/xml'
  content_type :ics, 'text/calendar'
  default_format :json

  helpers do
    ID_DESC = 'ID or REF ref:[value]'.freeze
  end

  resource :plannings do
    desc 'Fetch customer\'s plannings.',
      nickname: 'getPlannings',
      entity: V01::Entities::Planning
    params do
      optional :ids, type: Array[String], desc: 'Select returned plannings by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    get do
      if env['api.format'] == :ics
        if params.key?(:email)
          current_customer.plannings.each do |planning|
            planning.routes.joins(vehicle_usage: [:vehicle]).select{ |route| route.vehicle_usage.vehicle.contact_email }.each do |route|
              route_calendar_email route
            end
          end
          status 204
        else
          plannings_calendar(current_customer.plannings).to_ical
        end
      else
        plannings = if params.key?(:ids)
          current_customer.plannings.select{ |planning|
            params[:ids].any?{ |s| ParseIdsRefs.match(s, planning) }
          }
        else
          current_customer.plannings.load
        end
        present plannings, with: V01::Entities::Planning
      end
    end

    desc 'Fetch planning.',
      nickname: 'getPlanning',
      entity: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      id = ParseIdsRefs.read params[:id]
      planning = current_customer.plannings.where(id).first!
      if env['api.format'] == :ics
        if params.key?(:email)
          planning.routes.joins(vehicle_usage: [:vehicle]).select{ |route| route.vehicle_usage.vehicle.contact_email }.each do |route|
            route_calendar_email route
          end
          status 204
        else
          planning_calendar(planning).to_ical
        end
      else
        present planning, with: V01::Entities::Planning
      end
    end
  end
end
