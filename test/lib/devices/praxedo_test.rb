require 'test_helper'

class PraxedoTest < ActionController::TestCase

  require Rails.root.join('test/lib/devices/praxedo_base')
  include PraxedoBase

  setup do
    @customer = add_praxedo_credentials customers(:customer_one)
    @service = Mapotempo::Application.config.devices.praxedo
  end

  test 'check authentication' do
    with_stubs [:get_events_wsdl, :get_events] do
      assert_nothing_raised do
        params = {
            login: @customer.devices[:praxedo][:login],
            password: @customer.devices[:praxedo][:password]
        }
        assert @service.check_auth params
      end
    end
  end

  test 'send route' do
    with_stubs [:create_events_wsdl, :create_events] do
      set_route
      assert_nothing_raised do
        assert @service.send_route @customer, @route
      end
    end
  end

  # TODO: not working for now
  # test 'fetch stops' do
  #   with_stubs [:search_events_wsdl, :search_events] do
  #     set_route
  #     assert_nothing_raised do
  #       assert @service.fetch_stops(@customer, Time.new(2017, 9, 24, 0, 0, 0, '+02:00'))
  #     end
  #   end
  # end

  # FIXME: not used for now
  # test 'clear route' do
  #   with_stubs [:delete_events] do
  #     set_route
  #     assert_nothing_raised do
  #       @service.clear_route @customer, @route
  #     end
  #   end
  # end

  # FIXME: not used for now
  # test 'get vehicles positions' do
  #   with_stubs [:client_geolocalisation_wsdl, :get_last_position_for_agents] do
  #     assert @service.get_vehicles_pos(@customer)
  #   end
  # end
end
