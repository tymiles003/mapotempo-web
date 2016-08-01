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
module VisitsHelper
  def visit_quantities(visit, vehicle)
    quantities = []
    if visit.quantity1_1
      quantities << visit.localized_quantity1_1 + (vehicle && vehicle.capacity1_1_unit ? ' ' + vehicle.capacity1_1_unit : '')
    end
    if visit.quantity1_2
      quantities << visit.localized_quantity1_2 + (vehicle && vehicle.capacity1_2_unit ? ' ' + vehicle.capacity1_2_unit : '')
    end
    [quantities.size > 0 ? quantities.join(' - ') : nil]
  end
end
