# Copyright © Mapotempo, 2015
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


module MasternautWs

  def self.createPOICategory(client_poi, account, username, password)
    params = {
      category: {
        logo: 'client_green',
        name: 'mapotempo',
        reference: 'mapotempo',
      }
    }

    self.get(client_poi, nil, :create_poi_category, account, username, password, params)
  end

  def self.fetchPOI(client_poi, account, username, password)
    params = {
      filter: {
        categoryReference: 'mapotempo',
      },
      maxResults: 999999,
    }

    response = self.get(client_poi, nil, :search_poi, account, username, password, params)

    fetch = (response[:multi_ref] || []).select{ |e|
      e[:'@xsi:type'].end_with?(':POI')
    }.collect{ |e|
      e[:'reference']
    }.select{ |r|
      r
    }.collect{ |r|
      s = r.split(':')
      begin
        [s[0].to_i, DateTime.strptime(s[1].to_i(36).to_s, '%s')]
      rescue
      end
    }.select{ |r|
      r
    }
    fetch = Hash[fetch]
  end

  def self.createPOI(client_poi, account, username, password, waypoint)
    params = {
      poi: {
        address: {
           road: waypoint[:street],
           city: waypoint[:city],
           zipCode: waypoint[:postalcode],
           country: '_',
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

    self.get(client_poi, 200, :create_poi, account, username, password, params)
  end

  def self.createJobRoute(account, username, password, vehicleRef, reference, description, begin_time, end_time, waypoints)
    client_poi = Savon.client(basic_auth: [username, password], wsdl: Mapotempo::Application.config.masternaut_api_url + '/POI?wsdl', soap_version: 1) do
      #log true
      #pretty_print_xml true
      convert_request_keys_to :none
    end

    existing_waypoints = self.fetchPOI(client_poi, account, username, password)
    if existing_waypoints.empty? then
      self.createPOICategory(client_poi, account, username, password)
    end

    waypoints.select{ |waypoint|
      # Send only non existing waypoints or updated
      !existing_waypoints[waypoint[:id]] || waypoint[:updated_at].change(:usec => 0) > existing_waypoints[waypoint[:id]]
    }.each{ |waypoint|
      self.createPOI(client_poi, account, username, password, waypoint)
    }

    params = {
      jobRoute: {
        begin: Time.now.strftime('%Y-%m-%dT') + begin_time.strftime('%H:%M:%S'),
        description: description ? description.strip[0..50] : nil,
        end: Time.now.strftime('%Y-%m-%dT') + end_time.strftime('%H:%M:%S'),
        reference: reference,
      }
    }

    client_Job = Savon.client(basic_auth: [username, password], wsdl: Mapotempo::Application.config.masternaut_api_url + '/Job?wsdl', multipart: true, soap_version: 1) do
      #log true
      #pretty_print_xml true
      convert_request_keys_to :none
    end
    self.get(client_Job, 1, :create_job_route, account, username, password, params)


    waypoints.each{ |waypoint|
      params = {
        job: {
          description: waypoint[:description][0..255],
          poiReference: [waypoint[:id], waypoint[:updated_at].to_i.to_s(36)].join(':'),
          scheduledBegin: Time.now.strftime('%Y-%m-%dT') + waypoint[:time].strftime('%H:%M:%S'),
          type: 'job',
          vehicleRef: vehicleRef,
        },
#        poi: {
#          address: {
#            road: waypoint[:street],
#            city: waypoint[:city],
#            zipCode: waypoint[:postalcode],
#            country: '_',
#          },
##          category: {
##            logo: 'client_green',
##            name: 'mapotempo',
##            reference: 'mapotempo',
##          },
#          latitude: waypoint[:lat],
#          longitude: waypoint[:lng],
#          name: waypoint[:name],
##          reference: [waypoint[:id], waypoint[:updated_at].to_s(36)].join(':'),
#        },
        jobRouteRef: reference,
      }

      self.get(client_Job, 1, :create_job, account, username, password, params)
    }
  end

  private
    def self.get(client, no_error_code, operation, account, username, password, message = {})
      response = client.call(operation, message: message)

      _response = (operation.to_s + '_response').to_sym
      _return = (operation.to_s + '_return').to_sym
      if no_error_code && response.body[_response] && response.body[_response][_return] != no_error_code.to_s
        raise "#{operation} returns error code #{response.body[_response][_return]}"
      end
      response.body
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      raise fault_code
    rescue Savon::HTTPError => error
      Rails::logger.info error.http.code
      raise
    end
end
