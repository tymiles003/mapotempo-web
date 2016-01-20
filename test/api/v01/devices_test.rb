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
require 'test_helper'

class V01::DevicesTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  setup do
    @customer = customers(:customer_one)
  end

  def app
    Rails.application
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/#{part}?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should validate tomtom credentials' do
    begin
      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/v1.25/objectsAndPeopleReportingService?wsdl')
      stub_table = stub_request(:get, uri_template).to_return(File.new(Rails.root.join("test/web_mocks/soap.business.tomtom.com/objectsAndPeopleReportingService.wsdl")).read)

      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/v1.25/objectsAndPeopleReportingService')
      stub_table = stub_request(:post, uri_template).to_return(File.new(Rails.root.join("test/web_mocks/soap.business.tomtom.com/showObjectReportResponse.xml")).read)

      account_params = { account: "Account Name", user: "User Name", password: "User Password" }
      get api("/devices/tomtoms/check_credentials", account_params)
      assert last_response.ok?, last_response.body
    ensure
     remove_request_stub(stub_table)
    end
  end

end
