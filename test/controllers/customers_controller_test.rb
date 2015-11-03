require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @customer = customers(:customer_one)
    @vehicle_one = vehicles(:vehicle_one)
    sign_in users(:user_one)
  end

  test 'user can only edit its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :edit, customers(:customer_one)
    assert ability.can? :update, customers(:customer_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? [:manage], customers(:customer_one)
    ability = Ability.new(users(:user_admin))
    assert ability.can? :manage, customers(:customer_one)
    sign_in users(:user_three)
    get :edit, id: @customer
    assert_response :redirect
  end

  test 'should get edit' do
    get :edit, id: @customer
    assert_response :success
    assert_valid response
  end

  test 'should update customer' do
    patch :update, id: @customer, customer: { take_over: 123 }

    assert_redirected_to edit_customer_path(assigns(:customer))
  end

  test 'should destroy vehicles' do
    sign_in users(:user_admin)
    assert_difference('Vehicle.count', -1) do
      delete :delete_vehicle, customer_id: @customer.id, vehicle_id: @vehicle_one.id
    end
    assert_redirected_to edit_customer_path(assigns(:customer))
  end

  test 'should not destroy vehicles' do
    assert_difference('Vehicle.count', 0) do
      delete :delete_vehicle, customer_id: @customer.id, vehicle_id: @vehicle_one.id
    end
  end

  test 'should disabled max_vehicles field' do
    begin
      Mapotempo::Application.config.manage_vehicles_only_admin = true
      get :edit, id: @customer.id
      assert_response :success
      assert_select 'form input' do
        assert_select "[name='customer[max_vehicles]']" do
          assert_select '[disabled=?]', 'disabled'
        end
      end
    ensure
      Mapotempo::Application.config.manage_vehicles_only_admin = false
    end
  end

  test 'should not disabled max_vehicles field' do
    sign_in users(:user_admin)
    get :edit, id: @customer.id
    assert_response :success
    assert_select 'form input' do
      assert_select "[name='customer[max_vehicles]']" do
        assert_select '[disabled]', false
      end
    end
  end
end
