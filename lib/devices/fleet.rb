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

  TIMEOUT_VALUE ||= 600 # Only for post and delete

  USER_DEFAULT_ROLES = %w(mission.creating mission.updating mission.deleting user_current_location.creating user_current_location.updating user_track.updating user_track.updating)
  USER_DEFAULT_PASSWORD = '123456'

  def definition
    {
      device: 'fleet',
      label: 'Mapotempo Fleet',
      label_small: 'Fleet',
      route_operations: [:send, :clear],
      has_sync: true,
      has_create_device: true,
      has_create_user: true,
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

  def list_devices(customer, _params = {})
    response = rest_client_get(get_users_url(with_vehicle: true), customer.devices[:fleet][:api_key])
    data = JSON.parse(response.body)

    if response.code == 200 && data['users']
      data['users'].map do |user|
        {
          id: user['sync_user'],
          text: "#{user['name']} - #{user['email']}",
          color: user['color'] || '#000000'
        }
      end
    else
      raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.list')}")
    end
  rescue RestClient::Unauthorized, RestClient::InternalServerError
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.list')}")
  end

  def create_company(customer)
    admin_api_key = Mapotempo::Application.config.devices.fleet.admin_api_key
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.create_company.no_admin_api_key')}") unless admin_api_key

    begin
      # Create company with admin user
      user_email = customer.users.first.email.gsub(/@/, '+admin@')
      company_params = {
        name: customer.name,
        user_email: user_email
      }

      company = rest_client_post(set_company_url, admin_api_key, company_params)
      company = JSON.parse(company)['company']

      # Associate to customer
      customer.update!(devices: customer.devices.merge({
        fleet: {
          enable: true,
          user: user_email,
          api_key: company['admin_user']['api_key']
        }
      }))

      self.api_key = company['admin_user']['api_key']

      return company
    rescue RestClient::UnprocessableEntity => e
      error = JSON.parse(e.response)
      if error['name'] && error['name'][0] == 'has already been taken'
        raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.create_company.already_created')}")
      else
        raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.create_company.error')}")
      end
    rescue RestClient::Unauthorized, RestClient::InternalServerError
      raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.create_company.error')}")
    end
  end

  def create_drivers(customer)
    api_key = customer.devices[:fleet][:api_key]
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.create_drivers.no_api_key')}") unless api_key

    vehicles_with_email = customer.vehicles.select(&:contact_email)

    users = vehicles_with_email.map do |vehicle|
      driver_params = {
        name: vehicle.name,
        email: vehicle.contact_email,
        password: USER_DEFAULT_PASSWORD,
        roles: USER_DEFAULT_ROLES,
      }

      begin
        response = rest_client_post(set_user_url, api_key, driver_params)
        vehicle.update! devices: {fleet_user: JSON.parse(response)['user']['sync_user']}
        response
      rescue RestClient::UnprocessableEntity
        nil
      end
    end.compact

    if users.empty? && !vehicles_with_email.empty?
      raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.create_drivers.already_created')}")
    else
      users
    end
  end

  def get_vehicles_pos(customer)
    response = rest_client_get(get_vehicles_pos_url, customer.devices[:fleet][:api_key])
    data = JSON.parse(response.body)

    if response.code == 200 && data['user_current_locations']
      data['user_current_locations'].map do |current_location|
        {
          fleet_vehicle_id: current_location['sync_user'],
          device_name: current_location['name'],
          lat: current_location['location_detail']['lat'],
          lng: current_location['location_detail']['lon'],
          time: current_location['location_detail']['date'],
          speed: current_location['location_detail']['speed'] && (current_location['location_detail']['speed'].to_f * 3.6).round,
          direction: current_location['location_detail']['bearing']
        }
      end
    else
      raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.get_vehicles_pos')}")
    end
  rescue RestClient::Unauthorized, RestClient::InternalServerError
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.get_vehicles_pos')}")
  end

  def fetch_stops(customer, _date)
    response = get_missions(customer.devices[:fleet][:api_key])
    data = JSON.parse(response.body)

    if response.code == 200 && data['missions']
      data['missions'].map do |mission|
        # As planning only display status for today, ignore mission status different than today
        order_id, date = decode_mission_id(mission['external_ref'])
        date = Date.parse(date.gsub('_', '-')) rescue nil
        next unless date == Date.today

        {
          order_id: order_id,
          status: @@order_status[mission['status_type_label']],
          color: mission['status_type_color'],
          eta: nil
        }
      end.compact
    else
      raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.fetch_stops')}")
    end
  rescue RestClient::Unauthorized, RestClient::InternalServerError
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.fetch_stops')}")
  end

  def send_route(customer, route, _options = {})
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.past_missions')}") if route.planning.date && route.planning.date < Date.today

    destinations = route.stops.select(&:active?).select(&:position?).select { |stop| stop.is_a?(StopVisit) }.sort_by(&:index).map do |destination|
      labels = (destination.visit.tags + destination.visit.destination.tags).map(&:label).join(', ')
      quantities = destination.is_a?(StopVisit) ? (customer.enable_orders ? (destination.order ? destination.order.products.collect(&:code).join(',') : '') : destination.visit.default_quantities ? VisitQuantities.normalize(destination.visit, route.vehicle_usage.try(&:vehicle)).map { |d| "\u2022 #{d[:quantity]}" }.join("\r\n") : '') : nil
      time_windows = []
      time_windows << {
        start: p_time(route, destination.open1).strftime('%FT%T.%L%:z'),
        end: p_time(route, destination.close1).strftime('%FT%T.%L%:z')
      } if destination.open1 && destination.close1
      time_windows << {
        start: p_time(route, destination.open2).strftime('%FT%T.%L%:z'),
        end: p_time(route, destination.close2).strftime('%FT%T.%L%:z')
      } if destination.open2 && destination.close2

      {
        external_ref: generate_mission_id(destination, planning_date(route.planning)),
        name: destination.name,
        date: p_time(route, destination.time).strftime('%FT%T.%L%:z'),
        location: {
          lat: destination.lat,
          lon: destination.lng
        },
        comment: [
          destination.comment,
          destination.priority ? I18n.t('activerecord.attributes.visit.priority') + I18n.t('text.separator') + destination.priority_text : nil,
          labels.present? ? I18n.t('activerecord.attributes.visit.tags') + I18n.t('text.separator') + labels : nil,
          quantities.present? ? I18n.t('activerecord.attributes.visit.quantities') + I18n.t('text.separator') + "\r\n" + quantities : nil
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
        time_windows: time_windows
      }
    end

    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.no_missions')}") if destinations.empty?

    send_missions(route.vehicle_usage.vehicle.devices[:fleet_user], customer.devices[:fleet][:api_key], destinations)
  rescue RestClient::Unauthorized, RestClient::InternalServerError, RestClient::ResourceNotFound, RestClient::UnprocessableEntity
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.set_missions')}")
  end

  def clear_route(customer, route, use_date = true)
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.past_missions')}") if route.planning.date && route.planning.date < Date.today

    if use_date
      start_date = (planning_date(route.planning) + (route.start || 0)).strftime('%Y-%m-%d')
      end_date = (planning_date(route.planning) + (route.end || 0) + 2.day).strftime('%Y-%m-%d')
      delete_missions_by_date(route.vehicle_usage.vehicle.devices[:fleet_user], customer.devices[:fleet][:api_key], start_date, end_date)
    else
      destination_ids = route.stops.select(&:active?).select(&:position?).sort_by(&:index).map do |destination|
        generate_mission_id(destination, planning_date(route.planning))
      end
      delete_missions(route.vehicle_usage.vehicle.devices[:fleet_user], customer.devices[:fleet][:api_key], destination_ids)
    end
  rescue RestClient::Unauthorized, RestClient::InternalServerError, RestClient::ResourceNotFound, RestClient::UnprocessableEntity
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
  rescue RestClient::RequestTimeout, Errno::ECONNREFUSED, SocketError
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.timeout')}")
  end

  def rest_client_post(url, api_key, params)
    RestClient::Request.execute(
      method: :post,
      url: url,
      headers: { content_type: :json, accept: :json, Authorization: "Token token=#{api_key}" },
      payload: params.to_json,
      timeout: TIMEOUT_VALUE
    )
  rescue RestClient::RequestTimeout
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.timeout')}")
  end

  def rest_client_delete(url, api_key)
    RestClient::Request.execute(
      method: :delete,
      url: url,
      headers: { content_type: :json, accept: :json, Authorization: "Token token=#{api_key}" },
      timeout: TIMEOUT_VALUE
    )
  rescue RestClient::RequestTimeout
    raise DeviceServiceError.new("Fleet: #{I18n.t('errors.fleet.timeout')}")
  end

  def set_company_url
    URI.encode("#{api_url}/api/0.1/companies")
  end

  def get_users_url(params = {})
    URI.encode(Addressable::Template.new("#{api_url}/api/0.1/users{?with_vehicle*}").expand(params).to_s)
  end

  def get_user_url(user)
    URI.encode("#{api_url}/api/0.1/users/#{convert_user(user)}")
  end

  def set_user_url
    URI.encode("#{api_url}/api/0.1/users")
  end

  def get_vehicles_pos_url
    URI.encode("#{api_url}/api/0.1/user_current_locations")
  end

  def get_missions_url(user = nil)
    user ? URI.encode("#{api_url}/api/0.1/users/#{convert_user(user)}/missions") : URI.encode("#{api_url}/api/0.1/missions")
  end

  def set_missions_url(user)
    URI.encode("#{api_url}/api/0.1/users/#{convert_user(user)}/missions/create_multiples")
  end

  def delete_missions_url(user, destination_ids)
    URI.encode("#{api_url}/api/0.1/users/#{convert_user(user)}/missions/destroy_multiples?#{destination_ids.to_query('ids')}")
  end

  def delete_missions_by_date_url(user, start_date, end_date)
    URI.encode("#{api_url}/api/0.1/users/#{convert_user(user)}/missions/destroy_multiples?start_date=#{start_date}&end_date=#{end_date}")
  end

  def generate_mission_id(destination, date)
    order_id = destination.is_a?(StopVisit) ? "v#{destination.visit_id}" : "r#{destination.id}"
    "mission-#{order_id}-#{date.strftime('%Y_%m_%d')}"
  end

  def convert_user(user)
    # Convert to SHA256 if user is a email address
    user && user.include?('@') ? Digest::SHA256.hexdigest(user) : user
  end

  def decode_mission_id(mission_ref)
    mission_ref.split('-')[1, 2]
  end

end
