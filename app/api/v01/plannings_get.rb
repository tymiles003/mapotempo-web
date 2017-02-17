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

    def get_format_routes_email(planning_ids)
      hash = current_customer.vehicles.select(&:contact_email).group_by(&:contact_email)
      struct = hash.each{ |email, vehicles|
        hash[email] = vehicles.map{ |v| {
          vehicle: v,
          routes: v.vehicle_usages.flat_map{ |vu|
            vu.routes.select{ |r|
              planning_ids.include?(r.planning_id)
            }.map{ |r| {
              url: api_route_calendar_path(r, api_key: @current_user.api_key),
              route: r
            }}
          }
        }
      }}
    end
  end

  resource :plannings do
    desc 'Fetch customer\'s plannings.',
      nickname: 'getPlannings',
      success: V01::Entities::Planning
    params do
      optional :ids, type: Array[String], desc: 'Select returned plannings by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    get do
      plannings = current_customer.plannings
      plannings = plannings.select{ |plan| params[:ids].any?{ |s| ParseIdsRefs.match(s, plan) } } if params.key?(:ids)
      if env['api.format'] == :ics
          if params.key?(:email) && YAML.load(params[:email])
            planning_ids = plannings.map(&:id)
            emails_routes = get_format_routes_email(planning_ids)
            route_calendar_email(emails_routes)
            status 204
          else
            plannings_calendar(plannings).to_ical
          end
      else
        present plannings, with: V01::Entities::Planning
      end
    end

    desc 'Fetch planning.',
      nickname: 'getPlanning',
      success: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      planning = current_customer.plannings.where(ParseIdsRefs.read(params[:id])).first!
      if env['api.format'] == :ics
        if params.key?(:email)
          emails_routes = get_format_routes_email([planning.id])
          route_calendar_email(emails_routes)
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
