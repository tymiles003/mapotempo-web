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
    ID_DESC = 'ID or REF ref:[value]'
  end

  resource :plannings do
    desc 'Fetch planning.',
      nickname: 'getPlanning',
      entity: V01::Entities::Planning
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      id = ParseIdsRefs.read params[:id]
      planning = current_customer.plannings.where(id).first!
      if params.key?(:email)
        planning.routes.joins(vehicle_usage: [:vehicle]).select{ |route| route.vehicle_usage.vehicle.contact_email }.each do |route|
          icalendar_export_email route
        end
        status 204
      else
        if env['api.format'] == :ics
          icalendar_planning_export planning
        else
          present planning, with: V01::Entities::Planning
        end
      end
    end
  end
end
