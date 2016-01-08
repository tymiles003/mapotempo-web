# Copyright © Mapotempo, 2013-2014
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
module VehiclesHelper

  def vehicle_usage_emission vehicle_usage
    return if !vehicle_usage.vehicle.emission
    "%s %s".html_safe % [ vehicle_usage.vehicle.emission, t('all.unit.kgco2e_l_html') ]
  end

  def vehicle_usage_consumption vehicle_usage
    return if !vehicle_usage.vehicle.consumption
    "%s %s".html_safe % [ vehicle_usage.vehicle.consumption, t('all.unit.l_100km') ]
  end

  def vehicle_usage_router vehicle_usage
    capture do
      if vehicle_usage.vehicle.router && vehicle_usage.vehicle.router.name
        concat vehicle_usage.vehicle.router.name
      elsif @customer.router
        concat content_tag(:span, @customer.router.name, style: "color:grey")
      end
    end
  end

  def vehicle_usage_store_name vehicle_usage
    capture do
      if vehicle_usage.store_start || vehicle_usage.store_stop
        if vehicle_usage.default_store_start
          concat vehicle_usage.default_store_start.name
        else
          concat fa_icon("ban", title: t('vehicle_usages.index.store.no_start'))
        end
        if vehicle_usage.default_store_start != vehicle_usage.default_store_stop
          concat " "
          concat fa_icon("long-arrow-right")
          concat " "
        end
        if vehicle_usage.default_store_stop
          concat vehicle_usage.default_store_stop.name
        else
          concat fa_icon("ban", title: t('vehicle_usages.index.store.no_stop'))
        end
      elsif vehicle_usage.default_store_start
        concat fa_icon("exchange", title: t('vehicle_usages.index.store.same_start_stop'))
      end
    end
  end

  def vehicle_usage_store_hours vehicle_usage
    capture do
      if vehicle_usage.open
        concat l(vehicle_usage.open, format: :hour_minute)
        concat " - "
      elsif vehicle_usage.vehicle_usage_set.open
        concat content_tag(:span, l(vehicle_usage.vehicle_usage_set.open, format: :hour_minute), style: "color:grey")
        concat content_tag(:span, " - ", style: "color:grey")
      end
      if vehicle_usage.close
        concat l(vehicle_usage.close, format: :hour_minute)
      elsif vehicle_usage.vehicle_usage_set.close
        concat content_tag(:span, l(vehicle_usage.vehicle_usage_set.close, format: :hour_minute), style: "color:grey")
      end
    end
  end

end
