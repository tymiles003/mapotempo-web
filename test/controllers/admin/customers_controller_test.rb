require 'test_helper'

class Admin::CustomersControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @controller = CustomersController.new
    @customer = customers(:customer_one)
    sign_in users(:user_admin)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_valid response
  end

  test 'should get edit' do
    get :edit, id: @customer
    assert_response :success
    assert_valid response
  end

  test 'should create customer' do
    assert_difference('Customer.count') do
      post :create, customer: { name: 'new', max_vehicles: 2, default_country: 'France', speed_multiplicator: 1, profile_id: profiles(:profile_one), router: routers(:router_one).id.to_s + '_time' }
    end
    assert_redirected_to edit_customer_path(assigns(:customer))
  end

  test 'should update customer' do
    patch :update, id: @customer, customer: { take_over: 123, enable_orders: !@customer.enable_orders }

    assert_redirected_to edit_customer_path(assigns(:customer))
  end

  test 'should destroy customer' do
    assert_difference('Customer.count', -1) do
      delete :destroy, id: @customer
    end

    assert_redirected_to customers_path
  end

  test 'should destroy multiple customer' do
    assert_difference('Customer.count', -2) do
      delete :destroy_multiple, customers: { customers(:customer_one).id => 1, customers(:customer_one_other).id => 1 }
    end

    assert_redirected_to customers_path
  end
end
