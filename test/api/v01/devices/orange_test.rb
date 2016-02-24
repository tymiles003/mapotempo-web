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

class V01::Devices::OrangeTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  setup do
    @customer = customers(:customer_one)
    @customer = add_orange_credentials @customer
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
          when :auth
            expected_response = File.read(Rails.root.join("test/web_mocks/orange/blank.xml")).strip
            uri = URI.parse OrangeService::URL ; url = "%s://%s:%s@%s%s" % [ uri.scheme, @customer.orange_user, @customer.orange_password, uri.host, "/pnd/index.php" ]
            stubs << stub_request(:get, url).with(query: hash_including({ })).to_return(status: 200, body: expected_response)
          when :send
            expected_response = File.read(Rails.root.join("test/web_mocks/orange/blank.xml")).strip
            uri = URI.parse OrangeService::URL ; url = "%s://%s:%s@%s%s" % [ uri.scheme, @customer.orange_user, @customer.orange_password, uri.host, "/pnd/index.php" ]
            stubs << stub_request(:post, url).with(query: hash_including({ })).to_return(status: 200, body: expected_response)
          when :get_vehicles
            expected_response = File.read(Rails.root.join("test/web_mocks/orange/get_vehicles.xml")).strip
            uri = URI.parse OrangeService::URL ; url = "%s://%s:%s@%s%s" % [ uri.scheme, @customer.orange_user, @customer.orange_password, uri.host, "/webservices/getvehicles.php" ]
            stubs << stub_request(:get, url).with(body: { ext: "xml" }).to_return(status: 200, body: expected_response)
          when :vehicles_pos
            expected_response = File.read(Rails.root.join("test/web_mocks/orange/get_vehicles_pos.xml")).strip
            uri = URI.parse OrangeService::URL ; url = "%s://%s:%s@%s%s" % [ uri.scheme, @customer.orange_user, @customer.orange_password, uri.host, "/webservices/getpositions.php" ]
            stubs << stub_request(:get, url).with(body: { ext: "xml" }).to_return(status: 200, body: expected_response)
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
    with_stubs [:auth] do
      get api("devices/orange/auth")
      assert last_response.ok?, last_response.body
    end
  end

  test 'list devices' do
    with_stubs [:get_vehicles] do
      get api("devices/orange/devices", { customer_id: @customer.id })
      assert last_response.ok?, last_response.body
      assert_equal [{"id"=>"325000749", "text"=>"Eric 590 - DB-116-CL"}], JSON.parse(last_response.body)
    end
  end

  test 'vehicle positions' do
    with_stubs [:vehicles_pos] do
      vehicle = @customer.vehicles.take
      vehicle.update! orange_id: '325000749' # Match response vehicle_id
      get api("vehicles/current_position")
      assert last_response.ok?, last_response.body
      assert_equal [{
        "vehicle_id"=>vehicle.id,
        "device_name"=>"Eric 590",
        "lat"=>"44.813109",
        "lng"=>"-0.562738",
        "direction"=>nil,
        "speed"=>"2",
        "time"=>"2016-02-16 11:19:35"}
      ], JSON.parse(last_response.body)
    end
  end

  test 'send' do
    with_stubs [:send] do
      set_route
      post api("devices/orange/send", { customer_id: @customer.id, route_id: @route.id })
      assert last_response.ok?, last_response.body
    end
  end

  test 'clear' do
    with_stubs [:send] do
      set_route
      delete api("devices/orange/clear", { customer_id: @customer.id, route_id: @route.id })
      assert last_response.ok?, last_response.body
    end
  end

  private

  def set_route
    @route = routes(:route_one_one)
    @route.update! end: @route.start + 5.hours
    @route.planning.update! date: 10.days.from_now
  end

  def add_orange_credentials customer
    customer.enable_orange = true
    customer.orange_user = "OrangeUser"
    customer.orange_password = "OrangePassword"
    customer.save!
    customer
  end
end
