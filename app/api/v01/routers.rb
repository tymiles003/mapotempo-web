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
class V01::Routers < Grape::API
  resource :routers do
    desc 'Fetch customer\'s routers.',
      detail: 'Get the list of available routers which can be used for finding route.',
      nickname: 'getRouters',
      is_array: true,
      success: V01::Entities::Router
    get do
      if @current_user.admin?
        error! 'Forbidden, empty customer', 403
      else
        present @current_customer.profile.routers.load, with: V01::Entities::Router
      end
    end
  end
end
