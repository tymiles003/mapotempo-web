# Copyright © Mapotempo, 2016
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
class V01::Devices < Grape::API
  namespace :devices do
    namespace :tomtoms do
      desc 'Check TomTom Credentials',
        detail: 'Validate TomTom WebFleet Credentials',
        nickname: 'checkTomTomCredentials'

      get '/check_credentials' do
        customer = current_customer params[:customer_id]
        account  = params[:account]  ? params[:account]   : customer.try(:tomtom_account)
        user     = params[:user]     ? params[:user]      : customer.try(:tomtom_user)
        passwd   = params[:password] ? params[:password]  : customer.try(:tomtom_password)
        begin
          Mapotempo::Application.config.tomtom.showObjectReport account, user, passwd
          status 200
        rescue TomTomError => e
          error! e.message, 200
        end
      end
    end
  end
end
