# Copyright © Mapotempo, 2014
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
require 'tomtom_webfleet'

class Tomtom

  def self.export_route(customer, route)
    lang = 'fr' ############################################################### FIXME

    TomtomWebfleet.clearOrdersExtern(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, lang, route.vehicle.tomtom_id)

    route.stops.each{ |stop|
      TomtomWebfleet.sendDestinationOrderExtern(customer.tomtom_account, customer.tomtom_user, customer.tomtom_password, lang, route.vehicle.tomtom_id, stop)
    }
  end
end
