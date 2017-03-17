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
class Trimble < DeviceBase
  def definition
    {
      device: 'trimble',
      label: 'Trimble',
      label_small: 'Trimble',
      route_operations: [:send],
      has_sync: false,
      help: false,
      forms: {
        settings: {
          customer: :text,
          username: :text,
          password: :password
        },
        vehicle: {
          trimble_ref: :text
        },
      }
    }
  end

  def check_auth(params)
    client ||= Savon.client(basic_auth: [params[:trimble_username] || '', params[:trimble_password] || ''], wsdl: api_url + '/Customer?wsdl', soap_version: 1) do
      # log true
      # pretty_print_xml true
      convert_request_keys_to :none
    end

    get(client, nil, :get_customer_info, {}, {})
  end

  def get(client, no_error_code, operation, message = {}, error_code)
    response = client.call(operation, message: message)
    op_response = (operation.to_s + '_response').to_sym
    op_return = (operation.to_s + '_return').to_sym

    if !response.body.key?(op_response)
      Rails.logger.info response.body[op_response]
      raise DeviceServiceError.new("Trimble operation #{operation} returns error: #{error_code[response.body[op_response][op_return]] || response.body[op_response][op_return]}")
    end

    response.body
  rescue Savon::SOAPFault => error
    Rails.logger.info error
    fault_code = error.to_hash[:fault][:faultcode]
    fault_string = error.to_hash[:fault][:faultstring]
    raise DeviceServiceError.new("Trimble : #{fault_code} #{fault_string}")
  rescue Savon::HTTPError => error
    Rails.logger.info error.http.code
    raise error
  end
end
