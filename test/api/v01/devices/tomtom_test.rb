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

class V01::Devices::TomtomTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  setup do
    @customer = customers(:customer_one)
    @customer = add_tomtom_credentials @customer
  end

  def app
    Rails.application
  end

  def api path, params = {}
    Addressable::Template.new("/api/0.1/#{path}.json{?query*}").expand(query: params.merge(api_key: 'testkey1')).to_s
  end

  def with_stubs names, &block
    begin
      stubs = []
      names.each do |name|
        case name
          when :client_objects_wsdl
            url = Addressable::Template.new "https://soap.business.tomtom.com/v1.25/objectsAndPeopleReportingService?wsdl"
            stubs << stub_request(:get, url).to_return(File.read(Rails.root.join("test/web_mocks/soap.business.tomtom.com/objectsAndPeopleReportingService.wsdl")))
          when :client_objects_api
            url = Addressable::Template.new "https://soap.business.tomtom.com/v1.25/objectsAndPeopleReportingService"
            stubs << stub_request(:post, url).to_return(File.read(Rails.root.join("test/web_mocks/soap.business.tomtom.com/showObjectReportResponse.xml")))
          when :client_orders_wsdl
            url = Addressable::Template.new "https://soap.business.tomtom.com/v1.25/ordersService?wsdl"
            stubs << stub_request(:get, url).to_return(File.read(Rails.root.join("test/web_mocks/soap.business.tomtom.com/ordersService.wsdl")))
          when :client_orders_api
            url = Addressable::Template.new "https://soap.business.tomtom.com/v1.25/ordersService"
            stubs << stub_request(:post, url).to_return(File.read(Rails.root.join("test/web_mocks/soap.business.tomtom.com/ordersService.xml")))
        end
      end
      yield
    ensure
      stubs.each do |name|
        remove_request_stub name
      end
    end
  end

  test 'authenticate' do
    with_stubs [:client_objects_wsdl, :client_objects_api] do
      get api("devices/tomtom/auth")
      assert last_response.ok?, last_response.body
    end
  end

  test 'list devices' do
    with_stubs [:client_objects_wsdl, :client_objects_api] do
      get api("devices/tomtom/devices", { customer_id: @customer.id })
      assert last_response.ok?, last_response.body
      assert_equal [
        {"id"=>"1-44063-666E054E7", "text"=>"MAPO1"},
        {"id"=>"1-44063-666F24630", "text"=>"MAPO2"}
      ], JSON.parse(last_response.body)
    end
  end

  test 'vehicle positions' do
    with_stubs [:client_objects_wsdl, :client_objects_api] do
      vehicle = @customer.vehicles.take
      vehicle.update! tomtom_id: '1-44063-666E054E7' # Match response vehicle_id
      get api("vehicles/current_position")
      assert last_response.ok?, last_response.body
      assert_equal [{
        "vehicle_id"=>vehicle.id,
        "device_name"=>"MAPO1",
        "lat"=>43.319336,
        "lng"=>-0.367286,
        "direction"=>nil,
        "speed"=>nil,
        "time"=>"2015-12-07T09:34:28.000+00:00"
      }], JSON.parse(last_response.body)
    end
  end

  test 'send orders' do
    with_stubs [:client_orders_wsdl, :client_orders_api] do
      @route = routes(:route_one_one)
      post api("devices/tomtom/send", { customer_id: @customer.id, route_id: @route.id, type: "orders" })
      assert last_response.ok?, last_response.body
    end
  end

  test 'send waypoints' do
    with_stubs [:client_orders_wsdl, :client_orders_api] do
      @route = routes(:route_one_one)
      post api("devices/tomtom/send", { customer_id: @customer.id, route_id: @route.id, type: "waypoints" })
      assert last_response.ok?, last_response.body
    end
  end

  test 'clear' do
    with_stubs [:client_orders_wsdl, :client_orders_api] do
      @route = routes(:route_one_one)
      delete api("devices/tomtom/clear", { customer_id: @customer.id, route_id: @route.id })
      assert last_response.ok?, last_response.body
    end
  end

  private

  def add_tomtom_credentials customer
    customer.enable_tomtom = true
    customer.tomtom_account = "TomTomAccount"
    customer.tomtom_user = "TomTomUser"
    customer.tomtom_password = "12345ABCD"
    customer.save!
    customer
  end

end
