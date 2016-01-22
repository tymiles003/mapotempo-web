# Copyright © Mapotempo, 2014-2016
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
require 'savon'

class TomTomError < StandardError ; end

class TomtomWebfleet
  TIME_2000 = Time.new(2000, 1, 1, 0, 0, 0, '+00:00').to_i

  VEHICLE_COLOR = {
    'white' => '#ffffff',
    'grey' => '#808080',
    'black' => '#000000',
    'ivory' => '#FFFFF0',
    'red' => '#FF0000',
    'orange' => '#FFA500',
    'yellow' => '#FFFF00',
    'green' => '#008000',
    'blue' => '#0000FF',
  }

  VEHICLE_TYPE = {
    'truck' => ['heavyweight_truck_trailer', 'tanker_truck', 'heavy_truck', 'medium_truck', 'dump_truck', 'pallet_truck', 'concrete_lorry', 'deposit_tipper', 'garbage_truck', 'loader', 'excavator', 'wrecker', 'truck_wrecker', 'heavyweight_truck', 'truck_with_trailer', 'bus', 'firetruck'],
    'car' => ['multicar', 'street_sweeper', 'tractor', 'ambulance', 'police', 'van', 'multivan', 'pickup', 'suv', 'taxi', 'car'],
    'vespa' => ['ape', 'vespa'],
    'bike' => ['bike'],
    nil: [nil, 'trailer', 'truck_trailer', 'crane', 'caddy', 'car_station_wagon', 'containership', 'link'],
  }

  attr_accessor :client_objects, :client_orders, :api_key, :cache_object

  def initialize(url, api_key, cache_object)
    @api_key = api_key
    @cache_object = cache_object

    @client_objects = Savon.client(wsdl: url + '/objectsAndPeopleReportingService?wsdl', multipart: true, soap_version: 2, open_timeout: 60, read_timeout: 60) do
      #log true
      #pretty_print_xml true
      convert_request_keys_to :none
    end

    @client_address = Savon.client(wsdl: url + '/addressService?wsdl', multipart: true, soap_version: 2, open_timeout: 60, read_timeout: 60) do
      #log true
      #pretty_print_xml true
      convert_request_keys_to :none
    end

    @client_orders = Savon.client(wsdl: url + '/ordersService?wsdl', multipart: true, soap_version: 2, open_timeout: 60, read_timeout: 60) do
      #log true
      #pretty_print_xml true
      convert_request_keys_to :none
    end
  end

  def showObjectReport(account, username, password)
    key = ['tomtom', account, username, password, @client_object]
    result = @cache_object.read(key)
    if !result
      objects = get(@client_objects, :show_object_report, account, username, password, {})
      objects = [objects] if objects.is_a?(Hash)
      result = objects.select{ |object| !object[:deleted] }.collect{ |object|
        {
          objectUid: object[:@object_uid],
          objectName: object[:object_name],
          lat: (object[:position] && object[:position][:latitude] && (object[:position][:latitude].to_i / 1e6)),
          lng: (object[:position] && object[:position][:longitude] && (object[:position][:longitude].to_i / 1e6)),
          speed: object[:speed],
          direction: object[:course],
          # quality: object[:quality],
          time: object[:pos_time],
        }
      }
      @cache_object.write(key, result)
    end
    result
  end

  def showVehicleReport(account, username, password)
    vehicles = get(@client_objects, :show_vehicle_report, account, username, password, {})
    vehicles = [vehicles] if vehicles.is_a?(Hash)
    vehicles.select{ |object| !object[:deleted] }.collect{ |vehicle|
      {
        uid: vehicle[:@object_uid],
        name: vehicle[:object_name],
#        type: ->(vehicle[:vehicletype]) { |type| VEHICLE_TYPE.find{ |k, v| v.include?(type) }.first },
#        color: VEHICLE_COLOR[vehicle[:vehiclecolor]],
      }
    }
  end

  def showAddressReport(account, username, password)
    addresss = get(@client_address, :show_address_report, account, username, password, {})
    addresss = [addresss] if addresss.is_a?(Hash)
    addresss.select{ |object| !object[:deleted] }.collect{ |address|
      {
        ref: address[:@address_uid] && 'tomtom:' + address[:@address_uid],
        name: address[:name1] || address[:name2] || address[:name3],
        comment: [address[:info], address[:contact][:contactName]].compact.join(', '),
        street: address[:location][:street],
        postalcode: address[:location][:postcode],
        city: address[:location][:city],
        country: address[:location][:country],
        lat: (address[:location][:geo_position] && address[:location][:geo_position][:latitude] && address[:location][:geo_position][:latitude].to_i / 1e6),
        lng: (address[:location][:geo_position] && address[:location][:geo_position][:longitude] && address[:location][:geo_position][:longitude].to_i / 1e6),
        detail: address[:location][:description],
#        state: address[:location][:addrRegion],
        phone_number: address[:contact][:phoneBusiness] || address[:contact][:phoneMobile] || address[:contact][:phonePersonal],
      }
    }
  end

  def clearOrders(account, username, password, objectuid)
    get(@client_orders, :clear_orders, account, username, password,
      deviceToClear: {
        markDeleted: 'true',
      },
      attributes!: {
        deviceToClear: {
          objectUid: objectuid,
        }
      }
    )
  end

  def sendDestinationOrder(account, username, password, objectuid, date, position, orderid, description, time, waypoints = nil)
    unique_base_oder_id = (orderid.to_s + Time.now.to_i.to_s).to_i.to_s(36)
    params = {
      dstOrderToSend: {
        orderText: description.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\s+/, ' ').strip[0..499],
        explicitDestination: {
          street: (position.street[0..49] if position.street),
          postcode: (position.postalcode[0..9] if position.postalcode),
          city: (position.city[0..49] if position.city),
          geoPosition: '',
          attributes!: {
            geoPosition: {
              latitude: (position.lat * 1e6).round.to_s,
              longitude: (position.lng * 1e6).round.to_s,
            }
          },
          order!: [:street, :postcode, :city, :geoPosition]
        }
      },
      object: '',
      attributes!: {
        object: {
          objectUid: objectuid,
        },
        dstOrderToSend: {
          orderNo: (description.gsub(/[^a-z0-9\s]/i, '')[0..(19 - unique_base_oder_id.length)] + unique_base_oder_id).upcase,
          orderType: 'DELIVERY_ORDER',
        }
      }
    }

    (params[:attributes!][:dstOrderToSend][:scheduledCompletionDateAndTime] = (date.to_time + (time.to_i - TIME_2000)).strftime('%Y-%m-%dT%H:%M:%S')) if time

    if waypoints
      params[:advancedSendDestinationOrderParm] = {waypoints: {
        waypoint: waypoints.collect{ |waypoint|
          {
            latitude: (waypoint[:lat] * 1e6).round.to_s,
            longitude: (waypoint[:lng] * 1e6).round.to_s,
            description: waypoint[:description].gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(',', ' ').gsub(/\s+/, ' ').strip[0..19]
          }
        }
      }}
    end
    get(@client_orders, :send_destination_order, account, username, password, params)
  end

  private

  def get(client, operation, account, username, password, message = {})
    message[:order!] = [:aParm, :gParm] + (message[:order!] || (message.keys - [:attributes!]))
    message[:aParm] = {
      apiKey: @api_key,
      accountName: account,
      userName: username,
      password: password,
    }
    message[:gParm] = {}
    response = client.call(operation, message: message)
    ret = response.body.first[1][:return]
    status_code = ret[:status_code].to_i

    if status_code != 0
      Rails.logger.info "%s: %s" % [ operation, response.body ]
      raise TomTomError.new("TomTom: %s" % [ parse_error_msg(status_code) || ret[:status_message] ])
    else
      ret[:results][:result_item] if ret.key?(:results)
    end

  rescue Savon::SOAPFault => error
    Rails.logger.info error
    fault_code = error.to_hash[:fault][:faultcode]
    raise "TomTomWebFleet: #{fault_code}"
  rescue Savon::HTTPError => error
    Rails.logger.info error.http.code
    raise error
  end

  def parse_error_msg status_code
    # https://uk.support.business.tomtom.com/ci/fattach/get/1331065/1450429305/redirect/1/session/L2F2LzEvdGltZS8xNDUyNjk2OTAzL3NpZC9yVVVpQ3FHbQ==/filename/WEBFLEET.connect-en-1.26.0.pdf
    case status_code
      when 45
        I18n.t "errors.tomtom.access_denied"
      when 1101
        I18n.t "errors.tomtom.invalid_account"
      when 8014
        I18n.t "errors.tomtom.external_requests_not_allowed"
      when 9126
        I18n.t "errors.tomtom.hostname_not_allowed"
    end
  end

end
