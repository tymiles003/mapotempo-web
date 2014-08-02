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
require 'savon'


module TomtomWebfleet

  @client = Savon.client(wsdl: Mapotempo::Application.config.tomtom_api + '/ordersService?wsdl', multipart: true, soap_version: 2) do
    #log true
    #pretty_print_xml true
    convert_request_keys_to :none
  end

  def self.clearOrders(account, username, password, objectuid)
    self.get(:clear_orders, account, username, password, {
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

  def self.sendDestinationOrder(account, username, password, objectuid, stop, orderid, description, waypoints = nil)
    params = {
      dstOrderToSend: {
        orderText: description.strip[0..499],
        explicitDestination: {
          street: (stop.destination.street[0..49] if stop.destination.street),
          postcode: (stop.destination.postalcode[0..9] if stop.destination.postalcode),
          city: (stop.destination.city[0..49] if stop.destination.city),
          geoPosition: '',
          :attributes! => {
            geoPosition: {
              latitude: (stop.destination.lat*1e6).round.to_s,
              longitude: (stop.destination.lng*1e6).round.to_s,
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
          orderNo: orderid,
          orderType: 'DELIVERY_ORDER',
        }
      }
    }

    (params[:attributes!][:dstOrderToSend][:scheduledCompletionDateAndTime] = Time.now.strftime('%Y-%m-%dT') + stop.time.strftime('%H:%M:%S')) if stop.time

    if waypoints
      params[:advancedSendDestinationOrderParm] = {waypoints: {
        waypoint: waypoints.collect{ |waypoint|
          {
            latitude: (waypoint[:lat]*1e6).round.to_s,
            longitude: (waypoint[:lng]*1e6).round.to_s,
            description: waypoint[:description].gsub(',', ' ')[0..19]
          }
        }
      }}
    end
    self.get(:send_destination_order, account, username, password, params)
  end

  private
    def self.get(operation, account, username, password, message = {})
      message[:order!] = [:aParm, :gParm] + (message[:order!] || (message.keys - [:attributes!]))
      message[:aParm] = {
        accountName: account,
        userName: username,
        password: password,
      }
      message[:gParm] = {}
      response = @client.call(operation, message: message)

      if response.body.first[1][:return][:status_code] != '0'
        raise response.body.first[1][:return][:status_message]
      end
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      raise fault_code
    rescue Savon::HTTPError => error
      Rails::logger.info error.http.code
      raise
    end
end
