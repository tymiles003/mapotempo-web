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

require 'net/ftp'
require 'tempfile'

class Notico < DeviceBase
  def definition
    {
        device: 'notico',
        label: 'Notico',
        label_small: 'Notico',
        route_operations: [:send, :clear],
        has_sync: false,
        help: true,
        forms: {
            settings: {
                ftp_url: :text,
                username: :text,
                password: :password
            },
            vehicle: {
                agentId: :text
            },
        }
    }
  end

  def check_auth(credentials)
    get(credentials)
  end

  def send_route(customer, route, options = {})
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.interventions {
        route.stops.select { |s| s.active && s.position? && !s.is_a?(StopRest) }.collect do |stop|
          xml.intervention(interId: stop.base_id, tourId: stop.route_id, agentId: route.vehicle_usage.vehicle.devices[:agentId], action: options[:delete] ? 'delete' : nil) {
            unless options[:delete]
              xml.customer {
                xml.name stop.name
                xml.language I18n.locale.to_s.upcase
                xml.address [stop.street, stop.detail].compact.join(' ')
                xml.zip_code stop.postalcode
                xml.city stop.city
                xml.country stop.country || customer.default_country
                xml.phone stop.phone_number || ''
                xml.instructions stop.comment if stop.comment
              }

              start_time = stop.time
              end_time = stop.duration ? stop.time + stop.duration.seconds : stop.time
              xml.dt_firststart p_time(route, start_time).strftime('%F %H:%M')
              xml.dt_firstend p_time(route, end_time).strftime('%F %H:%M')

              xml.todo {
                xml.item {
                  xml.col_1 { xml.cdata(stop.ref || '') }
                  xml.col_2 { xml.cdata((customer.enable_orders ? (stop.order ? stop.order.products.collect(&:code).join(',') : '') : customer.deliverable_units.map { |du| stop.visit.default_quantities[du.id] && "x#{stop.visit.default_quantities[du.id]}#{du.label}" }.compact.join(' '))) }
                  xml.col_3 ''
                  xml.col_4 ''
                }
              }

              xml.signature 'non'
            end
          }
        end
      }
    end

    credentials = customer.devices[:notico]
    get(credentials, {
        filename: "flux_livraisons#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.xml",
        xml_content: builder.to_xml
    })
  end

  def clear_route(customer, route)
    send_route(customer, route, delete: true)
  end

  private

  def get(credentials, message = {})
    ftp = nil

    begin
      ftp = Net::FTP.new(credentials[:ftp_url])
      ftp.passive = true
      ftp.login(credentials[:username], credentials[:password])

      if message[:filename] && message[:xml_content]
        ftp.chdir('out/')

        temp_file = Tempfile.new(message[:filename])
        temp_file.write(message[:xml_content])
        temp_file.close

        ftp.putbinaryfile(temp_file, message[:filename])

        temp_file.unlink
      end

      ftp.close
    rescue
      raise DeviceServiceError.new("Notico: #{ftp.last_response}")
    end
  end
end
