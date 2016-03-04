require 'test_helper'

class AlyacomTest < ActionController::TestCase

  require Rails.root.join("test/lib/devices/alyacom_base")
  include AlyacomBase

  setup do
    @customer = add_alyacom_credentials customers(:customer_one)
    @service = Mapotempo::Application.config.devices.alyacom
    @service.set_params customer: @customer
  end

  test 'send route' do
    with_stubs({ get: [:staff, :users, :planning], post: [:staff, :users, :planning] }) do
      set_route
      assert_nothing_raised do
        @service.send_route route: @route
      end
    end
  end

end
