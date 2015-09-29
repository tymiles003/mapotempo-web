require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @customer = customers(:customer_one)
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
end
