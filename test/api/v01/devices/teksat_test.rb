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

class V01::Devices::TeksatTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  setup do
    @customer = customers(:customer_one)
    @customer = add_teksat_credentials @customer
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
            @ticket_id = File.read(Rails.root.join("test/web_mocks/teksat/get_ticket")).strip
            url = TeksatService.new({}).send :get_ticket_url, @customer.teksat_url, @customer.teksat_customer_id, @customer.teksat_username, @customer.teksat_password
            stubs << stub_request(:get, url).to_return(status: 200, body: @ticket_id)
          when :get_vehicles
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/get_vehicles.xml")).strip
            url = TeksatService.new(customer: @customer, ticket_id: @ticket_id).send :get_vehicles_url
            stubs << stub_request(:get, url).to_return(status: 200, body: expected_response)
          when :vehicles_pos
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/get_vehicles_pos.xml")).strip
            url = TeksatService.new(customer: @customer, ticket_id: @ticket_id).send :get_vehicles_pos_url
            stubs << stub_request(:get, url).to_return(status: 200, body: expected_response)
          when :send_route
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/mission_data.xml")).strip
            url = @customer.teksat_url + "/webservices/map/set-mission.jsp"
            stubs << stub_request(:get, url).with(:query => hash_including({ })).to_return(status: 200, body: expected_response)
          when :clear_route
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/get_missions.xml")).strip
            url = @customer.teksat_url + "/webservices/map/get-missions.jsp"
            stubs << stub_request(:get, url).with(:query => hash_including({ })).to_return(status: 200, body: expected_response)
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/mission_data.xml")).strip
            url = @customer.teksat_url + "/webservices/map/delete-mission.jsp"
            stubs << stub_request(:get, url).with(:query => hash_including({ })).to_return(status: 200, body: expected_response)
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
      get api("devices/teksat/auth")
      assert last_response.ok?, last_response.body
    end
  end

  test 'list devices' do
    with_stubs [:auth, :get_vehicles] do
      get api("devices/teksat/devices", { customer_id: @customer.id })
      assert last_response.ok?, last_response.body
      assert_equal [
        {"id"=>"97", "text"=>"FIAT DOBLO - 352848026546057"},
        {"id"=>"98", "text"=>"FIAT DOBLO - 352848026546131"},
        {"id"=>"95", "text"=>"FIAT DOBLO - 352848026626164"},
        {"id"=>"96", "text"=>"FIAT DOBLO - 352848026664710"}
      ], JSON.parse(last_response.body)
    end
  end

  test 'vehicle positions' do
    with_stubs [:auth, :vehicles_pos] do
      vehicle = @customer.vehicles.take
      vehicle.update! teksat_id: '1091' # Match response vehicle_id
      get api("vehicles/current_position")
      assert last_response.ok?, last_response.body
      assert_equal [{
        "vehicle_id"=>vehicle.id,
        "device_name"=>"356173064830644",
        "lat"=>"49.1860415",
        "lng"=>"-0.3810453",
        "direction"=>nil,
        "speed"=>"0",
        "time"=>"2016-02-10 15:20:31"
      }], JSON.parse(last_response.body)
    end
  end

  test 'send' do
    with_stubs [:auth, :send_route] do
      set_route
      post api("devices/teksat/send", { customer_id: @customer.id, route_id: @route.id })
      assert last_response.ok?, last_response.body
    end
  end

  test 'clear' do
    with_stubs [:auth, :clear_route] do
      set_route
      delete api("devices/teksat/clear", { customer_id: @customer.id, route_id: @route.id })
      assert last_response.ok?, last_response.body
    end
  end

  private

  def set_route
    @route = routes(:route_one_one)
    @route.update! end: @route.start + 5.hours
    @route.planning.update! date: 10.days.from_now
  end

  def add_teksat_credentials customer
    customer.enable_teksat = true
    customer.teksat_customer_id = rand(100)
    customer.teksat_username = "TeksatUsername"
    customer.teksat_password = "TeksatPassword"
    customer.teksat_url = "www.gps00.teksat.fr"
    customer.save!
    customer
  end
end
