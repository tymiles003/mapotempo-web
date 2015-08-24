require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @user = users(:user_one)
    sign_in users(:user_one)
  end

  test 'should get edit_settings' do
    get :edit_settings, id: @user
    assert_response :success
  end

  test 'should update_settings user' do
    patch :update_settings, id: @user, user: { layer_id: @user.layer.id }
    assert_redirected_to edit_user_settings_path(assigns(:user))
  end
end
