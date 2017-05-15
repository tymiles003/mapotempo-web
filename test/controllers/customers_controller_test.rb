require 'test_helper'

class CustomersControllerTest < ActionController::TestCase

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @customer = customers(:customer_one)
  end

  test 'user can only edit its customer' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :edit, customers(:customer_one)
    assert ability.can? :update, customers(:customer_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? [:manage], customers(:customer_one)
    ability = Ability.new(users(:user_admin))
    assert ability.can? :manage, customers(:customer_one)

    sign_in users(:user_one)
    get :edit, id: customers(:customer_two)
    assert_response :redirect
  end

  test 'should get edit' do
    sign_in users(:user_one)
    get :edit, id: @customer
    assert_response :success
    assert_valid response
  end

  test 'should update customer' do
    sign_in users(:user_one)
    patch :update, id: @customer, customer: {name: 123, router_dimension: 'distance', router_options: {motorway: true, trailers: 2, weight: 10, hazardous_goods: 'gas'}}
    assert_redirected_to [:edit, @customer]
    assert_equal 'distance', @customer.reload.router_dimension
    # FIXME: replace each assertion by one which checks if hash is included in another
    assert @customer.reload.router_options['motorway'] = 'true'
    assert @customer.reload.router_options['trailers'] = '2'
    assert @customer.reload.router_options['weight'] = '10'
    assert @customer.reload.router_options['hazardous_goods'] = 'gas'
  end

  test 'should not destroy vehicles' do
    assert_difference('Vehicle.count', 0) do
      delete :delete_vehicle, id: @customer.id, vehicle_id: vehicles(:vehicle_one).id
    end
  end

  test 'should delete customer' do
    sign_in users(:user_admin)
    delete :destroy, id: @customer.id
    assert_redirected_to customers_path
    assert !assigns(:customer).persisted?
  end

  test 'should delete multiple customers' do
    sign_in users(:user_admin)
    delete :destroy_multiple, {customers: {@customer.id => 1}}
    assert_redirected_to customers_path
  end

  test 'should disabled max_vehicles field' do
    begin
      Mapotempo::Application.config.manage_vehicles_only_admin = true
      sign_in users(:user_one)
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
    sign_in users(:user_one)
    get :edit, id: @customer.id
    assert_response :success
    assert_select 'form input' do
      assert_select "[name='customer[max_vehicles]']" do
        assert_select '[disabled]', false
      end
    end
  end
end
