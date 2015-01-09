require 'test_helper'

class CustomersControllerAdminTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @controller = CustomersController.new
    @customer = customers(:customer_one)
    sign_in users(:user_admin)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @customer
    assert_response :success
  end

  test "should update customer" do
    patch :update, id: @customer, customer: { take_over: 123, enable_orders: !@customer.enable_orders }

    assert_redirected_to edit_customer_path(assigns(:customer))
  end

  test "should destroy customer" do
    assert_difference('Customer.count', -1) do
      delete :destroy, id: @customer
    end

    assert_redirected_to customers_path
  end
end
