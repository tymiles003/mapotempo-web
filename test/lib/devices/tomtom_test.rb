require 'test_helper'

class TomtomTest < ActionController::TestCase

  require Rails.root.join("test/lib/devices/tomtom_base")
  include TomtomBase

  setup do
    @customer = add_tomtom_credentials customers(:customer_one)
    @service = Mapotempo::Application.config.devices.tomtom
    @service.set_params customer: @customer
  end

  test 'test list' do
    with_stubs [:client_objects_wsdl, :object_report] do
      assert @service.test_list account: @customer.tomtom_account, user: @customer.tomtom_user, password: @customer.tomtom_password
    end
  end

  test 'list devices' do
    with_stubs [:client_objects_wsdl, :object_report] do
      assert @service.list_devices
    end
  end

  test 'list vehicles' do
    with_stubs [:client_objects_wsdl, :vehicle_report] do
      assert @service.list_vehicles
    end
  end

  test 'list addresses' do
    with_stubs [:address_service_wsdl, :address_service] do
      assert @service.list_addresses
    end
  end

  test 'send route as waypoints' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      assert_nothing_raised do
        @service.send_route route: @route, type: :waypoints
      end
    end
  end

  test 'send route as orders' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      assert_nothing_raised do
        @service.send_route route: @route, type: :orders
      end
    end
  end

  test 'clear route' do
    with_stubs [:orders_service_wsdl, :orders_service] do
      set_route
      assert_nothing_raised do
        @service.clear_route route: @route
      end
    end
  end

  test 'get vehicles positions' do
    with_stubs [:client_objects_wsdl, :object_report] do
      assert @service.get_vehicles_pos
    end
  end
end
