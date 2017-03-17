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

class V01::Devices::MasternautTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  require Rails.root.join("test/lib/devices/api_base")
  include ApiBase

  require Rails.root.join("test/lib/devices/masternaut_base")
  include MasternautBase

  setup do
    @customer = add_masternaut_credentials customers(:customer_one)
  end

  test 'send' do
    with_stubs [:poi_wsdl, :poi, :job_wsdl, :job] do
      set_route
      post api("devices/masternaut/send", { customer_id: @customer.id, route_id: @route.id })
      assert_equal 201, last_response.status, last_response.body
      @route.reload
      assert @route.reload.last_sent_at
      assert_equal({ "id" => @route.id, "last_sent_to" => 'Masternaut', "last_sent_at" => @route.last_sent_at.iso8601(3), "last_sent_at_formatted"=>I18n.l(@route.last_sent_at) }, JSON.parse(last_response.body))
    end
  end

  test 'send multiple' do
    with_stubs [:poi_wsdl, :poi, :job_wsdl, :job] do
      set_route
      post api("devices/masternaut/send_multiple", { customer_id: @customer.id, planning_id: @route.planning_id })
      assert_equal 201, last_response.status, last_response.body
      routes = @route.planning.routes.select(&:vehicle_usage).select{|route| route.vehicle_usage.vehicle.devices[:masternaut_ref] }
      routes.each &:reload
      routes.each{|route| assert route.last_sent_at }
      assert_equal(routes.map{|route| { "id" => route.id, "last_sent_to" => 'Masternaut', "last_sent_at" => route.last_sent_at.iso8601(3), "last_sent_at_formatted"=>I18n.l(route.last_sent_at) } }, JSON.parse(last_response.body))
    end
  end
end
