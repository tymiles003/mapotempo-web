# Copyright © Mapotempo, 2017
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
class Praxedo < DeviceBase

  def definition
    {
        device: 'praxedo',
        label: 'Praxedo',
        label_small: 'Praxedo',
        route_operations: [:send],
        has_sync: false,
        help: true,
        forms: {
            settings: {
                login: :text,
                password: :password
            },
            vehicle: {
                praxedo_agent_id: :text
            },
        }
    }
  end

  # FIXME: not used for now
  # def savon_client_geolocalisation(customer)
  #   Savon.client(wsdl: api_url + '2006_09_25/GeolocalisationDataService?wsdl', soap_version: 1, open_timeout: 60, read_timeout: 60) do
  #     log true
  #     pretty_print_xml true
  #     convert_request_keys_to :none
  #   end
  # end

  def savon_client_events(customer)
    Savon.client(basic_auth: [customer.devices[:praxedo][:login], customer.devices[:praxedo][:password]], wsdl: api_url + 'cxf/v6/BusinessEventManager?wsdl', env_namespace: :soapenv, soap_version: 2, multipart: true) do
      log true
      pretty_print_xml true
      convert_request_keys_to :none
    end
  end

  @@order_status = {
      'NEW' => nil,
      'QUALIFIED' => nil,
      'PRE_SCHEDULED' => 'Planned',
      'SCHEDULED' => 'Planned',
      'IN_PROGRESS' => 'Started',
      'COMPLETED' => 'Finished',
      'VALIDATED' => 'Finished'
  }

  def check_auth(params)
    client = Savon.client(basic_auth: [params[:login], params[:password]], wsdl: api_url + 'cxf/v6/BusinessEventManager?wsdl', env_namespace: :soapenv, soap_version: 2, multipart: true) do
      log true
      pretty_print_xml true
      convert_request_keys_to :none
    end

    get(client, :get_events, {
        requestedEvents: ['']
    })
  end

  def format_position(customer, route, position, options = {})
    # TODO: how to format quantities ?
    # quantities = (customer.enable_orders ? (position.order ? position.order.products.collect(&:code) : []) : customer.deliverable_units.map { |du| position.visit.default_quantities[du.id] && [du.label, position.visit.default_quantities[du.id]] }.compact)
    quantities = []

    # TODO: content description ?
    # description = [
    #     '',
    #     position.comment,
    #     position.is_a?(StopVisit) ? quantities : nil,
    #     position.open1 || position.close1 ? (position.open1 ? position.open1_time + number_of_days(position.open1) : '') + (position.open1 && position.close1 ? '-' : '') + (position.close1 ? (position.close1_time + number_of_days(position.close1) || '') : '') : nil,
    #     position.open2 || position.close2 ? (position.open2 ? position.open2_time + number_of_days(position.open2) : '') + (position.open2 && position.close2 ? '-' : '') + (position.close2 ? (position.close2_time + number_of_days(position.close2) || '') : '') : nil,
    # ].compact.join(' ').strip
    description = ''

    {
        coreData: {
            anomaly: false,
            creationDate: Time.now.strftime('%FT%T.%L%:z'),
            description: '',
            referentialData: {
                '@xsi:type': 'tns:externalReferentialData',
                customerName: position.name,
                location: {
                    address: [position.street, options[:stop] && position.detail].compact.join(' '),
                    city: position.city,
                    contact: options[:stop] && position.phone_number,
                    name: position.name,
                    zipCode: position.postalcode,
                    description: description,
                    geolocation: {
                        latitude: position.lat,
                        longitude: position.lng
                    }
                }
            }
        },
        id: encode_order_id(description, (position.is_a?(StopVisit) ? "v#{position.visit_id}" : "r#{position.id}")),
        qualificationData: {
            type: {
                id: 'ENT', # ENT or SAV
                duration: options[:stop] && position.duration / 60 # unit: min
            },
            # TODO: what field to use for quantities ?
            # expectedItems: quantities.map { |quantity|
            #   {
            #       reference: quantity[0],
            #       name: quantity[0],
            #       expectedQuantity: quantity[1]
            #   }
            # }
        },
        schedulingData: {
            agentId: {
                '@xsi:type': 'tns:externalEntityId',
                id: route.vehicle_usage.vehicle.devices[:praxedo_agent_id]
            },
            appointmentDate: (p_time(route, options[:appointment_time]).strftime('%FT%T.%L%:z') if options[:appointment_time]),
            schedulingDate: (p_time(route, options[:schedule_time]).strftime('%FT%T.%L%:z') if options[:schedule_time])
        }.compact
    }.compact
  end

  def send_route(customer, route)
    events = []

    start = route.vehicle_usage.default_store_start
    if start && !start.lat.nil? && !start.lng.nil?
      events << format_position(customer, route, start, appointment_time: route.start)
    end

    route.stops.select { |s| s.active && s.position? && !s.is_a?(StopRest) }.map do |stop|
      events << format_position(customer, route, stop, stop: true, appointment_time: stop.open1 || stop.close1 || stop.open2 || stop.close2, schedule_time: stop.time)
    end

    stop = route.vehicle_usage.default_store_stop
    if stop && !stop.lat.nil? && !stop.lng.nil?
      events << format_position(customer, route, stop, appointment_time: route.stop)
    end

    get(savon_client_events(customer), :create_events, events: events)
  end

  def fetch_stops(customer, date)
    orders = []

    begin
      response = get(savon_client_events(customer), :search_events, {
          request: {
              agentIdConstraint: customer.vehicles.map { |v| v.devices[:praxedo_agent_id] }.compact,
              dateConstraints: {
                  name: 'schedulingDate', # available types: creationDate, appointmentDate, schedulingDate
                  dateRange: [date.strftime('%FT%T.%L%:z'), (date + 2.day).strftime('%FT%T.%L%:z')] # FIXME: change 2 days
              }
          },
          firstResultIndex: orders.size,
          batchSize: 50 # return 50 paginated results
      })

      response = response[:entities]
      if !response.is_a?(Array)
        orders += [response]
      else
        orders += response
      end
    end while (response && !response.empty?)

    orders.collect { |order| {
        # TODO
        # order_id: decode_order_id(order[:order_id]), #####################"
        status: @@order_status[order[:status]] || order[:status],
    } if order }.compact || []
  end

  # FIXME: not used for now
  # def clear_route(customer, route)
  #   events = route.stops.select { |s| s.active && s.position? && !s.is_a?(StopRest) }.map do |stop|
  #     {
  #         deleteEvents: {
  #             eventsToDelete: encode_order_id(description, (stop.is_a?(StopVisit) ? "v#{stop.visit_id}" : "r#{stop.id}"))
  #         }
  #     }
  #   end
  #
  #   get(savon_client_events(customer), :delete_events, events)
  # end

  # FIXME: not used for now
  # def get_vehicles_pos(customer)
  #   objects = get(savon_client_geolocalisation(customer), :get_last_position_for_agents, { authenticationString: "#{customer.devices[:praxedo][:login]}|#{customer.devices[:praxedo][:password]}" })
  #   objects.collect do |object|
  #     {
  #         #praxedo_agent_id:
  #         #device_name:
  #         lat: object[:position][0][0],
  #         lng: object[:position][0][1]
  #     }
  #   end if objects
  # end

  private

  def get(client, operation, message = {})
    response = client.call(operation, { message: message })

    response_body = if operation == :create_events
                      response.body[:create_events_response][:return]
                    elsif operation == :get_events
                      response.body[:get_events_response][:return]
                    else
                      response.body.first[1][:return]
                    end

    result_code = response_body[:result_code]
    if ['0', '200'].include?(result_code)
      if response_body[:results]
        return response_body[:results]
      else
        response_body
      end
    else
      raise DeviceServiceError.new("Praxedo: #{result_code}, #{response_body[:message]}")
    end

  rescue Savon::SOAPFault => error
    Rails.logger.info error
    fault_code = error.to_hash[:fault][:code][:value]
    fault_reason = error.to_hash[:fault][:reason][:text]
    raise "Praxedo: #{fault_code}, #{fault_reason}"
  rescue Savon::HTTPError => error
    Rails.logger.info error.http.code
    raise error
  end
end
