require 'test_helper'

class TeksatTest < ActionController::TestCase

  require Rails.root.join("test/lib/devices/teksat_base")
  include TeksatBase

  setup do
    @customer = add_teksat_credentials customers(:customer_one)
    @service = Mapotempo::Application.config.devices.teksat
    @service.set_params customer: @customer
  end

  test 'test list' do
    with_stubs [:auth] do
      assert @service.authenticate url: @customer.teksat_url, customer_id: @customer.teksat_customer_id, username: @customer.teksat_username, password: @customer.teksat_password
    end
  end

  test 'list devices' do
    with_stubs [:auth, :get_vehicles] do
      assert @service.list_devices
    end
  end

  test 'send route' do
    with_stubs [:auth, :send_route] do
      set_route
      assert_nothing_raised do
        @service.send_route route: @route
      end
    end
  end

  test 'clear route' do
    with_stubs [:auth, :clear_route] do
      set_route
      assert_nothing_raised do
        @service.clear_route route: @route
      end
    end
  end

  test 'get vehicles positions' do
    with_stubs [:auth, :vehicles_pos] do
      assert @service.get_vehicles_pos
    end
  end

end
