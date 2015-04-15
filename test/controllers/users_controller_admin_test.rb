require 'test_helper'

class UsersControllerAdminTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @controller = Admin::UsersController.new
    @user = users(:user_one)
    sign_in users(:user_admin)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, user: { customer_id: customers(:customer_one).id, email: "ty@io.com", password: "123456789"}
    end

    assert_redirected_to edit_customer_path(customers(:customer_one))
  end

  test "should not create user" do
    assert_difference('User.count', 0) do
      post :create, user: { email: "" }
    end

    assert_template :new
    user = assigns(:user)
    assert user.errors.any?
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    patch :update, id: @user, user: { email: "other email" }
    assert_response :success
  end

  test "should not update user" do
    patch :update, id: @user, user: { email: "" }
    assert_template :edit
    user = assigns(:user)
    assert user.errors.any?
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to admin_users_path
  end

  test "should destroy multiple user" do
    assert_difference('User.count', -2) do
      delete :destroy_multiple, users: { users(:user_one).id => 1, users(:user_two).id => 1 }
    end

    assert_redirected_to admin_users_path
  end
end
