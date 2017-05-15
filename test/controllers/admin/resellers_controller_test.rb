require 'test_helper'

class Admin::ResellersControllerTest < ActionController::TestCase

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @reseller = resellers(:reseller_one)
    sign_in users(:user_admin)
  end

  test 'should get edit' do
    get :edit, id: @reseller
    assert_response :success
    assert_valid response
  end

  test 'should update reseller' do
    patch :update, id: @reseller, reseller: { name: @reseller.name }
    assert_redirected_to edit_admin_reseller_path(@reseller)
  end
end
