require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @user = users(:user_one)
    sign_in users(:user_one)
    assert_valid response
  end

  test 'user can only manage itself' do
    ability = Ability.new(users(:user_one))
    assert ability.can? :edit, users(:user_one)
    assert ability.can? :update, users(:user_one)
    ability = Ability.new(users(:user_three))
    assert ability.cannot? :manage, users(:user_one)
    sign_in users(:user_three)
    get :edit_settings, id: @user
    assert_response :redirect
  end

  test 'admin user can only manage users from its customer' do
    ability = Ability.new(users(:user_admin))
    assert ability.can? :manage, users(:user_one)
    assert ability.cannot? :manage, users(:user_three)
  end

  test 'should get edit_settings' do
    get :edit_settings, id: @user
    assert_response :success
    assert_valid response
  end

  test 'should update_settings user' do
    patch :update_settings, id: @user, user: { layer_id: @user.layer.id }
    assert_redirected_to edit_user_settings_path(assigns(:user))
  end
end
