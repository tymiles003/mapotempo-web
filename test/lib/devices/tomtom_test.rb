require 'test_helper'

class TomtomTest < ActionController::TestCase

  require Rails.root.join("test/lib/devices/tomtom_base")
  include TomtomBase

  setup do
    @customer = add_tomtom_credentials customers(:customer_one)
    @service = Mapotempo::Application.config.devices.tomtom
  end

  test 'check authentication' do
    with_stubs [:client_objects_wsdl, :show_object_report] do
      params = {
        account: @customer.devices[:tomtom][:account],
        user: @customer.devices[:tomtom][:user],
        password: @customer.devices[:tomtom][:password]
      }
      assert @service.check_auth params
    end
  end

  test 'list devices' do
    with_stubs [:client_objects_wsdl, :show_object_report] do
      assert @service.list_devices @customer
    end
  end

  test 'list vehicles' do
    with_stubs [:client_objects_wsdl, :show_vehicle_report] do
      assert @service.list_vehicles @customer
    end
  end

  test 'list addresses' do
    with_stubs [:address_service_wsdl, :show_address_report] do
      assert @service.list_addresses @customer
    end
  end

  test 'send route as waypoints' do
    with_stubs [:orders_service_wsdl, :send_destination_order] do
      set_route
      assert_nothing_raised do
        @service.send_route @customer, @route, { type: :waypoints }
      end
    end
  end

  test 'send route as orders' do
    with_stubs [:orders_service_wsdl, :send_destination_order] do
      set_route
      assert_nothing_raised do
        @service.send_route @customer, @route, { type: :orders }
      end
    end
  end

  test 'clear route' do
    with_stubs [:orders_service_wsdl, :send_destination_order, :clear_orders] do
      set_route
      assert_nothing_raised do
        @service.clear_route @customer, @route
      end
    end
  end

  test 'get vehicles positions' do
    with_stubs [:client_objects_wsdl, :show_object_report] do
      assert @service.get_vehicles_pos @customer
    end
  end

  test 'should code and decode stop id' do
    id = 758944
    code = @service.send(:encode_order_id, 'plop', id)
    decode = @service.send(:decode_order_id, code)
    assert decode, id
  end
end
