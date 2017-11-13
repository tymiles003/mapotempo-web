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
class V01::Entities::Customer < Grape::Entity
  def self.entity_name
    'V01_Customer'
  end
  EDIT_ONLY_ADMIN = 'Only available in admin.'.freeze

  # expose(:reseller_id, documentation: { type: Integer, desc: EDIT_ONLY_ADMIN })
  # expose(:test, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  expose(:id, documentation: { type: Integer })
  expose(:end_subscription, documentation: { type: Date, desc: EDIT_ONLY_ADMIN })
  expose(:max_vehicles, documentation: { type: Integer, desc: EDIT_ONLY_ADMIN })

  # Default
  expose(:store_ids, documentation: { type: Integer, is_array: true })
  expose(:vehicle_usage_set_ids, documentation: { type: Integer, is_array: true })
  expose(:deliverable_unit_ids, documentation: { type: Integer, is_array: true })

  expose(:ref, documentation: { type: String, desc: EDIT_ONLY_ADMIN })
  expose(:name, documentation: { type: String, desc: EDIT_ONLY_ADMIN })
  expose(:default_country, documentation: { type: String })
  expose(:profile_id, documentation: { type: Integer, desc: EDIT_ONLY_ADMIN })
  expose(:router_id, documentation: { type: Integer })
  expose(:router_dimension, documentation: { type: String, values: ::Router::DIMENSION.keys })
  # FIXME: RouterOptions entity can only be used to display results, otherwise swagger-ui interface is broken but tests are ok. Entities are working correctly only with is_array.
  expose(:router_options, using: V01::Entities::RouterOptions, documentation: { type: V01::Entities::RouterOptions })

  expose(:speed_multiplicator, documentation: { type: Float })
  expose(:take_over, documentation: { type: DateTime, desc: 'Visit duration' }) { |m| m.take_over_time_with_seconds }
  expose(:print_planning_annotating, documentation: { type: 'Boolean' })
  expose(:print_header, documentation: { type: String })

  expose(:job_destination_geocoding_id, documentation: { type: Integer })
  expose(:job_store_geocoding_id, documentation: { type: Integer })
  expose(:job_optimizer_id, documentation: { type: Integer })

  expose(:enable_references, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  expose(:enable_multi_visits, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  expose(:enable_global_optimization, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  expose(:enable_vehicle_position, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  expose(:enable_stop_status, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  expose(:optimization_force_start, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  expose(:advanced_options, documentation: { type: String, desc: 'Advanced options in a serialized json format' })

  expose(:plannings_limitation, documentation: { type: Integer, desc: EDIT_ONLY_ADMIN })
  expose(:zonings_limitation, documentation: { type: Integer, desc: EDIT_ONLY_ADMIN })
  expose(:destinations_limitation, documentation: { type: Integer, desc: EDIT_ONLY_ADMIN })
  expose(:vehicle_usage_sets_limitation, documentation: { type: Integer, desc: EDIT_ONLY_ADMIN })

  expose(:devices, documentation: { type: Hash, desc: EDIT_ONLY_ADMIN })

  # # Devices: Alyacom
  # expose(:enable_alyacom, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  # expose(:alyacom_association, documentation: { type: String })

  # # Devices: Masternaut
  # expose(:enable_masternaut, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  # expose(:masternaut_user, documentation: { type: String })

  # # Devices: Orange
  # expose(:enable_orange, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  # expose(:orange_user, documentation: { type: String })

  # # Devices: Teksat
  # expose(:enable_teksat, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  # expose(:teksat_customer_id, documentation: { type: Integer })
  # expose(:teksat_username, documentation: { type: String })
  # expose(:teksat_url, documentation: { type: String })

  # # Devices: TomTom
  # expose(:enable_tomtom, documentation: { type: 'Boolean', desc: EDIT_ONLY_ADMIN })
  # expose(:tomtom_user, documentation: { type: String })
  # expose(:tomtom_account, documentation: { type: String })
  
end

class V01::Entities::CustomerAdmin < V01::Entities::Customer
  def self.entity_name
    'V01_CustomerAdmin'
  end
  EDIT_ONLY_ADMIN = 'Only available in admin.'.freeze

  expose(:description, documentation: { type: String, desc: EDIT_ONLY_ADMIN })
end
