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
require 'savon'

module TomtomWebfleet

  @client_objects = Savon.client(wsdl: Mapotempo::Application.config.tomtom_api_url + '/objectsAndPeopleReportingService?wsdl', multipart: true, soap_version: 2, open_timeout: 60, read_timeout: 60) do
    #log true
    #pretty_print_xml true
    convert_request_keys_to :none
  end

  @client_orders = Savon.client(wsdl: Mapotempo::Application.config.tomtom_api_url + '/ordersService?wsdl', multipart: true, soap_version: 2, open_timeout: 60, read_timeout: 60) do
    #log true
    #pretty_print_xml true
    convert_request_keys_to :none
  end

  def self.showObjectReport(account, username, password)
    objects = get(@client_objects, :show_object_report, account, username, password, {})
    objects = [objects] if objects.is_a?(Hash)
    objects.collect{ |object|
      {
        objectUid: object[:@object_uid],
        objectName: object[:object_name],
      }
    }
  end

  def self.clearOrders(account, username, password, objectuid)
    get(@client_orders, :clear_orders, account, username, password, {
      deviceToClear: {
        markDeleted: 'true',
      },
      :attributes! => {
        deviceToClear: {
          objectUid: objectuid,
        }
      }
   })
  end

  def self.sendDestinationOrder(account, username, password, objectuid, date, position, orderid, description, time, waypoints = nil)
    unique_base_oder_id = (orderid.to_s + Time.now.to_i.to_s).to_i.to_s(36)
    params = {
      dstOrderToSend: {
        orderText: description.strip[0..499],
        explicitDestination: {
          street: (position.street[0..49] if position.street),
          postcode: (position.postalcode[0..9] if position.postalcode),
          city: (position.city[0..49] if position.city),
          geoPosition: '',
          :attributes! => {
            geoPosition: {
              latitude: (position.lat * 1e6).round.to_s,
              longitude: (position.lng * 1e6).round.to_s,
            }
          },
          :order! => [:street, :postcode, :city, :geoPosition]
        }
      },
      object: '',
      :attributes! => {
        object: {
          objectUid: objectuid,
        },
        dstOrderToSend: {
          orderNo: (description.gsub(/[^a-z0-9\s]/i, '')[0..(19 - unique_base_oder_id.length)] + unique_base_oder_id).upcase,
          orderType: 'DELIVERY_ORDER',
        }
      }
    }

    (params[:attributes!][:dstOrderToSend][:scheduledCompletionDateAndTime] = date.strftime('%Y-%m-%dT') + time.strftime('%H:%M:%S')) if time

    if waypoints
      params[:advancedSendDestinationOrderParm] = {waypoints: {
        waypoint: waypoints.collect{ |waypoint|
          {
            latitude: (waypoint[:lat] * 1e6).round.to_s,
            longitude: (waypoint[:lng] * 1e6).round.to_s,
            description: waypoint[:description].gsub(',', ' ')[0..19]
          }
        }
      }}
    end
    get(@client_orders, :send_destination_order, account, username, password, params)
  end

  private

  def self.get(client, operation, account, username, password, message = {})
    message[:order!] = [:aParm, :gParm] + (message[:order!] || (message.keys - [:attributes!]))
    message[:aParm] = {
      apiKey: Mapotempo::Application.config.tomtom_api_key,
      accountName: account,
      userName: username,
      password: password,
    }
    message[:gParm] = {}
    response = client.call(operation, message: message)

    if response.body.first[1][:return][:status_code] != '0'
      Rails.logger.info response.body.first[1][:return]
      raise "TomTom WEBFLEET operation #{operation} return error: #{response.body.first[1][:return][:status_message]}"
    elsif response.body[:show_object_report_response]
      response.body[:show_object_report_response][:return][:results][:result_item]
    end
  rescue Savon::SOAPFault => error
    Rails.logger.info error
    fault_code = error.to_hash[:fault][:faultcode]
    raise fault_code
  rescue Savon::HTTPError => error
    Rails.logger.info error.http.code
    raise
  end
end
