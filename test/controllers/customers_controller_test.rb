require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @customer = customers(:customer_one)
    sign_in users(:user_one)
  end

  test "should get edit" do
    get :edit, id: @customer
    assert_response :success
  end

  test "should update customer" do
    patch :update, id: @customer, customer: { take_over: 123 }

    assert_redirected_to edit_customer_path(assigns(:customer))
  end
end
