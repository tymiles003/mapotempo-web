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
module VehicleUsagesHelper
  def vehicle_usage_emission_consumption(vehicle_usage)
    capture do
      concat '%s&nbsp;%s'.html_safe % [vehicle_usage.vehicle.localized_emission, t('all.unit.kgco2e_l_html')] if vehicle_usage.vehicle.emission
      concat ' - ' if vehicle_usage.vehicle.emission && vehicle_usage.vehicle.consumption
      concat '%s&nbsp;%s'.html_safe % [vehicle_usage.vehicle.localized_consumption, t('all.unit.l_100km')] if vehicle_usage.vehicle.consumption
    end
  end

  def vehicle_usage_router(vehicle_usage)
    capture do
      if vehicle_usage.vehicle.router
        concat [vehicle_usage.vehicle.router.name, t("activerecord.attributes.router.router_dimensions.#{vehicle_usage.vehicle.router_dimension || @customer.router_dimension}")].join(' - ')
      else
        concat span_tag([@customer.router.name, t("activerecord.attributes.router.router_dimensions.#{@customer.router_dimension}")].join(' - '))
      end
    end
  end

  def vehicle_usage_store_name(vehicle_usage)
    capture do
      if vehicle_usage.default_store_start || vehicle_usage.default_store_stop
        if vehicle_usage.store_start
          concat '%s ' % [vehicle_usage.store_start.name]
        elsif vehicle_usage.vehicle_usage_set.store_start
          if vehicle_usage.store_stop
            concat '%s ' % [vehicle_usage.vehicle_usage_set.store_start.name]
          else
            concat span_tag('%s ' % [vehicle_usage.vehicle_usage_set.store_start.name])
          end
        else
          concat fa_icon('ban', title: t('vehicle_usages.index.store.no_start'))
        end
        if vehicle_usage.default_store_start != vehicle_usage.default_store_stop
          concat fa_icon('long-arrow-right')
          concat ' '
          if vehicle_usage.store_stop
            concat ' %s' % [vehicle_usage.store_stop.name]
          elsif vehicle_usage.vehicle_usage_set.store_stop
            concat '%s ' % [vehicle_usage.vehicle_usage_set.store_stop.name]
          else
            concat fa_icon('ban', title: t('vehicle_usages.index.store.no_stop'))
          end
        elsif vehicle_usage.store_start
          concat fa_icon('exchange', title: t('vehicle_usages.index.store.same_start_stop'))
        elsif vehicle_usage.vehicle_usage_set.store_start
          concat span_tag(fa_icon('exchange', title: t('vehicle_usages.index.store.same_start_stop')))
        end
      end
    end
  end

  def vehicle_usage_store_hours(vehicle_usage)
    capture do
      if vehicle_usage.open
        concat l(vehicle_usage.open, format: :hour_minute)
        concat ' - '
      elsif vehicle_usage.vehicle_usage_set.open
        concat span_tag(l(vehicle_usage.vehicle_usage_set.open, format: :hour_minute))
        concat span_tag(' - ')
      end
      if vehicle_usage.close
        concat l(vehicle_usage.close, format: :hour_minute)
      elsif vehicle_usage.vehicle_usage_set.close
        concat span_tag(l(vehicle_usage.vehicle_usage_set.close, format: :hour_minute))
      end
    end
  end

  def vehicle_external_services(vehicle)
    services = []
    services << 'TomTom' if !vehicle.tomtom_id.blank?
    services << 'Teksat' if !vehicle.teksat_id.blank?
    services << 'Orange' if !vehicle.orange_id.blank?
    services.join(', ')
  end

  def route_description(route)
    capture do
      concat [route.size_active, t('plannings.edit.stops')].join(' ')
      if route.start && route.end
        concat ' - %i:%02i - ' % [
          (route.end - route.start) / 60 / 60,
          (route.end - route.start) / 60 % 60
        ]
      end
      concat number_to_human(route.distance, units: :distance, precision: 3)
      if route.vehicle_usage.default_service_time_start
        concat ' - %s: %s' % [
          t('activerecord.attributes.vehicle_usage.service_time_start'),
          l(route.vehicle_usage.default_service_time_start, format: :hour_minute)
        ]
      end
      if route.vehicle_usage.default_service_time_end
        concat ' - %s: %s' % [
          t('activerecord.attributes.vehicle_usage.service_time_end'),
          l(route.vehicle_usage.default_service_time_end, format: :hour_minute)
        ]
      end
    end
  end
end
