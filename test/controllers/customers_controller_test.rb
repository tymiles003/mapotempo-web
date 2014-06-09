require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
    sign_in users(:user_one)
  end

  test "should get edit" do
    get :edit, id: @customer
    assert_response :success
  end

  test "should update customer" do
    patch :update, id: @customer, customer: { take_over: @customer.take_over }

    assert_redirected_to edit_customer_path(assigns(:customer))
  end

  test "should stop job matrix" do
    # TODO
  end

  test "should stop job optimizer" do
    # TODO
  end

  test "should stop job geocoding" do
    # TODO
  end
end
