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
require 'addressable'

class Fleet < DeviceBase

  TIMEOUT_VALUE ||= 120

  def definition
    {
      device: 'fleet',
      label: 'Mapotempo Fleet',
      label_small: 'Fleet',
      route_operations: [:send, :clear],
      has_sync: true,
      help: true,
      forms: {
        settings: {
          user: :text,
          api_key: :password
        },
        vehicle: {
          fleet_user: :select
        }
      }
    }
  end

  # Available status in Mapotempo: Planned / Started / Finished / Rejected
  @@order_status = {
    'To do' => 'Planned',
    'In progress' => 'Started',
    'Completed' => 'Finished',
    'Uncompleted' => 'Rejected',
  }

  def check_auth(params)
    rest_client_get(get_user_url(params[:user]), params[:api_key])
  rescue RestClient::Forbidden, RestClient::InternalServerError, RestClient::ResourceNotFound, RestClient::Unauthorized, Errno::ECONNREFUSED
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.invalid_account')}")
  end

  def list_vehicles(customer, _params = {})
    response = rest_client_get(get_users_url(with_vehicle: true), customer.devices[:fleet][:api_key])
    data = JSON.parse(response.body)

    if response.code == 200 && data['users']
      data['users'].map do |user|
        {
          id: user['sync_user'],
          text: "#{user['sync_user']} - #{user['email']}",
          color: user['color'] || '#000000'
        }
      end
    else
      raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.list')}")
    end
  end

  def get_vehicles_pos(customer)
    response = rest_client_get(get_vehicles_pos_url, customer.devices[:fleet][:api_key])
    data = JSON.parse(response.body)

    if response.code == 200 && data['user_current_locations']
      data['user_current_locations'].map do |current_location|
        {
          fleet_vehicle_id: current_location['sync_user'],
          device_name: current_location['sync_user'],
          lat: current_location['location_detail']['lat'],
          lng: current_location['location_detail']['lon'],
          time: current_location['location_detail']['time'],
          speed: current_location['location_detail']['speed'] && (current_location['location_detail']['speed'].to_f * 3.6).round,
          direction: current_location['location_detail']['bearing']
        }
      end
    else
      raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.get_vehicles_pos')}")
    end
  end

  def fetch_stops(customer, _date)
    response = get_missions(customer.devices[:fleet][:api_key])
    data = JSON.parse(response.body)

    if response.code == 200 && data['missions']
      data['missions'].map do |mission|
        {
          order_id: decode_mission_id(mission['external_ref']),
          status: @@order_status[mission['status_type_label']],
          color: mission['status_type_color'],
          eta: nil
        }
      end
    else
      raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.fetch_stops')}")
    end
  end

  def send_route(customer, route, _options = {})
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.past_missions')}") if route.planning.date && route.planning.date < Date.today

    destinations = route.stops.select(&:active?).select(&:position?).select { |stop| stop.is_a?(StopVisit) }.sort_by(&:index).map do |destination|
      quantities = destination.is_a?(StopVisit) ? (customer.enable_orders ? (destination.order ? destination.order.products.collect(&:code).join(',') : '') : destination.visit.default_quantities ? VisitQuantities.normalize(destination.visit, route.vehicle_usage.try(&:vehicle)).map { |d| d[:quantity] }.join("\r\n") : '') : nil

      {
        external_ref: generate_mission_id(destination),
        name: destination.name,
        date: p_time(route, destination.time).strftime('%FT%T.%L%:z'),
        location: {
          lat: destination.lat,
          lon: destination.lng
        },
        comment: [
          destination.comment,
          quantities
        ].compact.join("\r\n\r\n").strip,
        phone: destination.phone_number,
        reference: destination.visit.destination.ref,
        duration: destination.duration,
        address: {
          city: destination.city,
          country: destination.country || customer.default_country,
          detail: destination.detail,
          postalcode: destination.postalcode,
          state: destination.state,
          street: destination.street
        },
        time_windows: [
          {
            start: p_time(route, destination.time).strftime('%FT%T.%L%:z'),
            end: p_time(route, destination.duration ? destination.time + destination.duration.seconds : destination.time).strftime('%FT%T.%L%:z')
          }
        ]
      }
    end

    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.no_missions')}") if destinations.empty?

    send_missions(route.vehicle_usage.vehicle.devices[:fleet_user], customer.devices[:fleet][:api_key], destinations)
  rescue RestClient::InternalServerError, RestClient::ResourceNotFound, RestClient::UnprocessableEntity
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.set_missions')}")
  end

  def clear_route(customer, route, use_date = true)
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.past_missions')}") if route.planning.date && route.planning.date < Date.today

    if use_date
      start_date = (planning_date(route.planning) + (route.start || 0)).strftime('%Y-%m-%d')
      end_date = (planning_date(route.planning) + (route.end || 0)).strftime('%Y-%m-%d')
      delete_missions_by_date(route.vehicle_usage.vehicle.devices[:fleet_user], customer.devices[:fleet][:api_key], start_date, end_date)
    else
      destination_ids = route.stops.select(&:active?).select(&:position?).sort_by(&:index).map do |destination|
        generate_mission_id(destination)
      end
      delete_missions(route.vehicle_usage.vehicle.devices[:fleet_user], customer.devices[:fleet][:api_key], destination_ids)
    end
  rescue RestClient::InternalServerError, RestClient::ResourceNotFound, RestClient::UnprocessableEntity
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.clear_missions')}")
  end

  private

  def get_missions(api_key, user = nil)
    rest_client_get(get_missions_url(user), api_key)
  end

  def send_missions(user, api_key, destinations)
    rest_client_post(set_missions_url(user), api_key, destinations)
  end

  def delete_missions(user, api_key, destination_ids)
    rest_client_delete(delete_missions_url(user, destination_ids), api_key)
  end

  def delete_missions_by_date(user, api_key, start_date, end_date)
    rest_client_delete(delete_missions_by_date_url(user, start_date, end_date), api_key)
  end

  def rest_client_get(url, api_key, _options = {})
    RestClient.get(
      url,
      { content_type: :json, accept: :json, Authorization: "Token token=#{api_key}" }
    )
  rescue RestClient::RequestTimeout
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.timeout')}")
  end

  def rest_client_post(url, api_key, params)
    RestClient.post(
      url,
      params.to_json,
      { content_type: :json, accept: :json, Authorization: "Token token=#{api_key}" }
    )
  rescue RestClient::RequestTimeout
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.timeout')}")
  end

  def rest_client_delete(url, api_key)
    RestClient.delete(
      url,
      { content_type: :json, accept: :json, Authorization: "Token token=#{api_key}" }
    )
  rescue RestClient::RequestTimeout
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.timeout')}")
  end

  def get_users_url(params = {})
    URI.encode(Addressable::Template.new("#{api_url}/api/0.1/users{?with_vehicle*}").expand(params).to_s)
  end

  def get_user_url(user)
    URI.encode("#{api_url}/api/0.1/users/#{user}")
  end

  def get_vehicles_pos_url
    URI.encode("#{api_url}/api/0.1/user_current_locations")
  end

  def get_missions_url(user = nil)
    user ? URI.encode("#{api_url}/api/0.1/users/#{user}/missions") : URI.encode("#{api_url}/api/0.1/missions")
  end

  def set_missions_url(user)
    URI.encode("#{api_url}/api/0.1/users/#{user}/missions/create_multiples")
  end

  def delete_missions_url(user, destination_ids)
    URI.encode("#{api_url}/api/0.1/users/#{user}/missions/destroy_multiples?#{destination_ids.to_query('ids')}")
  end

  def delete_missions_by_date_url(user, start_date, end_date)
    URI.encode("#{api_url}/api/0.1/users/#{user}/missions/destroy_multiples?start_date=#{start_date}&end_date=#{end_date}")
  end

  def generate_mission_id(destination)
    order_id = destination.is_a?(StopVisit) ? "v#{destination.visit_id}" : "r#{destination.id}"
    "mission-#{order_id}"
  end

  def decode_mission_id(mission_ref)
    mission_ref.split('mission-').last
  end

end
