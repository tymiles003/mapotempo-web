# Copyright © Mapotempo, 2015-2016
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
class Masternaut < DeviceBase
  attr_reader :client_poi, :client_job

  def savon_client_poi customer
    @client_poi ||= Savon.client(basic_auth: [customer.masternaut_user, customer.masternaut_password], wsdl: api_url + '/POI?wsdl', soap_version: 1) do
      #log true
      #pretty_print_xml true
      convert_request_keys_to :none
    end
  end

  def savon_client_job customer
    @client_job ||= Savon.client(basic_auth: [customer.masternaut_user, customer.masternaut_password], wsdl: api_url + '/Job?wsdl', multipart: true, soap_version: 1) do
      #log true
      #pretty_print_xml true
      convert_request_keys_to :none
    end
  end

  @@error_code_poi = {
    '200' => 'request has been successful',
    '403' => 'POI name or reference already exists',
    '404' => 'category has not been found',
    '405' => 'no coordinates given and address does not contain at least town and country',
    '406' => 'category reference already exists',
    '407' => 'category reference is too long',
    '408' => 'POI reference is too long',
    '409' => 'POI has not been found',
    '410' => 'POI logo has not been found',
    '411' => 'an error occurred while creating the category',
    '412' => 'an error occurred while creating the POI',
    '413' => 'an error occurred while deleting the POI',
    '414' => 'category reference already exists',
    '415' => 'category is not empty and the user tries to delete it',
    '416' => 'an unhandled exception occurs during POI category deletion',
    '417' => 'an error occured while it exists an incoherence between the fields temporary, startTemporary and endTemporary',
    '418' => 'The user attempt the update a reference, that it\'s not allowed.',
    '419' => 'poi reference missing',
    '420' => 'poi reference already exist on another POI',
  }

  @@error_code_job = {
    '1' => 'request has been successful',
    '2' => 'POI has not been found',
    '3' => 'driver has not been found',
    '4' => 'vehicle has not been found',
    '5' => 'neither driver nor vehicle has been set',
    '6' => 'no type has been set',
    '7' => 'the length of the job type is bigger than 30 characters',
    '8' => 'job route has already started',
    '9' => 'job route has not been found',
    '10' => 'job has not been found',
    '11' => 'job is already started. Its last job event code is greater or equals than 30 (ACCEPTED).',
    '12' => 'an error occurred while sending a message to the resource',
    '13' => 'an error occurred while creating the job',
    '14' => 'job reference already exists',
    '15' => 'job route reference already exists',
    '16' => 'both driver and vehicle references have been set',
    '17' => 'the length of the job route description is bigger than 50',
    '18' => 'item reference is missing',
    '19' => 'the length of the item reference is bigger than 50 characters',
    '20' => 'item label is missing',
    '21' => 'the length of the item label is bigger than 255 characters',
    '22' => 'item unit has not been set',
    '23' => 'the length of the item unit is bigger than 10 characters',
    '24' => 'item label already exists',
    '25' => 'item reference already exists',
    '26' => 'an error occurred while creating the job item',
  }

  def send_route customer, route, options={}
    order_id_base = Time.now.to_i.to_s(36) + '_' + route.id.to_s
    customer = route.planning.customer
    position = route.vehicle_usage.default_store_start
    waypoints = route.stops.select(&:active).collect{ |stop|
      position = stop if stop.position?
      if position.nil? || position.lat.nil? || position.lng.nil?
        next
      end
      {
        street: position.street,
        city: position.city,
        postalcode: position.postalcode,
        country: !position.country.nil? && !position.country.empty? ? country : customer.default_country,
        lat: position.lat,
        lng: position.lng,
        ref: stop.ref,
        name: stop.name,
        id: stop.base_id,
        description: [
          stop.name,
          stop.ref,
          stop.is_a?(StopVisit) ? (customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : stop.visit.quantity && stop.visit.quantity > 1 ? "x#{stop.visit.quantity}" : nil) : nil,
          stop.is_a?(StopVisit) ? (stop.visit.take_over ? '(' + stop.visit.take_over.strftime('%H:%M:%S') + ')' : nil) : route.vehicle_usage.default_rest_duration.strftime('%H:%M:%S'),
          stop.open || stop.close ? (stop.open ? stop.open.strftime('%H:%M') : '') + '-' + (stop.close ? stop.close.strftime('%H:%M') : '') : nil,
          stop.detail,
          stop.comment,
          stop.phone_number,
        ].compact.join(' ').strip,
        time: stop.time,
        updated_at: stop.base_updated_at,
      }
    }.compact
    if !position.nil? && !position.lat.nil? && !position.lng.nil?
      createJobRoute customer, route.vehicle_usage.vehicle.masternaut_ref, order_id_base, route.ref || route.vehicle_usage.vehicle.name, route.planning.date || Time.zone.today, route.start, route.end, waypoints
    end
  end

  private

  def createJobRoute customer, vehicleRef, reference, description, date, begin_time, end_time, waypoints
    time_2000 = Time.new(2000, 1, 1, 0, 0, 0, '+00:00').to_i

    existing_waypoints = fetchPOI(customer)
    if existing_waypoints.empty?
      createPOICategory(customer)
    end

    waypoints.select{ |waypoint|
      # Send only non existing waypoints or updated
      !existing_waypoints[waypoint[:id]] || waypoint[:updated_at].change(usec: 0) > existing_waypoints[waypoint[:id]]
    }.each{ |waypoint|
      createPOI(customer, waypoint)
    }

    params = {
      jobRoute: {
        begin: (date.to_time + (begin_time.to_i - time_2000)).strftime('%Y-%m-%dT%H:%M:%S'),
        description: description ? description.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\s+/, ' ').strip[0..50] : nil,
        end: (date.to_time + (end_time.to_i - time_2000)).strftime('%Y-%m-%dT%H:%M:%S'),
        reference: reference,
      }
    }

    get savon_client_job(customer), 1, :create_job_route, params, @@error_code_job

    waypoints.each{ |waypoint|
      params = {
        job: {
          description: waypoint[:description].gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\s+/, ' ').strip[0..255],
          poiReference: [waypoint[:id], waypoint[:updated_at].to_i.to_s(36)].join(':'),
          scheduledBegin: (date.to_time + (waypoint[:time].to_i - time_2000)).strftime('%Y-%m-%dT%H:%M:%S'),
          type: 'job',
          vehicleRef: vehicleRef,
        },
        jobRouteRef: reference,
      }

      get savon_client_job(customer), 1, :create_job, params, @@error_code_job
    }
  end

  def createPOICategory customer
    params = {
      category: {
        logo: 'client_green',
        name: 'mapotempo',
        reference: 'mapotempo',
      }
    }

    get savon_client_poi(customer), nil, :create_poi_category, params, @@error_code_poi
  end

  def fetchPOI customer
    params = {
      filter: {
        categoryReference: 'mapotempo',
      },
      maxResults: 999999,
    }

    response = get savon_client_poi(customer), nil, :search_poi, params, @@error_code_poi

    fetch = (response[:multi_ref] || []).select{ |e|
      e[:'@xsi:type'].end_with?(':POI')
    }.collect{ |e|
      e[:'reference']
    }.select{ |r|
      r
    }.collect{ |r|
      s = r.split(':')
      begin
        [Integer(s[0]), DateTime.strptime(s[1].to_i(36).to_s, '%s')]
      rescue
      end
    }.select{ |r|
      r
    }
    fetch = Hash[fetch]
  end

  def createPOI customer, waypoint
    params = {
      poi: {
        address: {
          road: waypoint[:street],
          city: waypoint[:city],
          zipCode: waypoint[:postalcode],
          country: waypoint[:country],
        },
        category: {
          logo: 'client_green',
          name: 'mapotempo',
          reference: 'mapotempo',
        },
        latitude: waypoint[:lat],
        longitude: waypoint[:lng],
        name: waypoint[:name],
        reference: [waypoint[:id], waypoint[:updated_at].to_i.to_s(36)].join(':'),
      },
      overwrite: true
    }

    get savon_client_poi(customer), 200, :create_poi, params, @@error_code_poi
  end

  def get client, no_error_code, operation, message={}, error_code
    response = client.call(operation, message: message)

    op_response = (operation.to_s + '_response').to_sym
    op_return = (operation.to_s + '_return').to_sym
    if no_error_code && response.body[op_response] && response.body[op_response][op_return] != no_error_code.to_s
      Rails.logger.info response.body[op_response]
      raise DeviceServiceError.new("Masternaut operation #{operation} returns error: #{error_code[response.body[op_response][op_return]] || response.body[op_response][op_return]}")
    end
    response.body
  rescue Savon::SOAPFault => error
    Rails.logger.info error
    fault_code = error.to_hash[:fault][:faultcode]
    raise "Masternaut: #{fault_code}"
  rescue Savon::HTTPError => error
    Rails.logger.info error.http.code
    raise error
  end
end
