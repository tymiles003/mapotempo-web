require 'test_helper'

class StopsControllerTest < ActionController::TestCase
  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @stop = stops(:stop_one_one)
    sign_in users(:user_one)
  end

  test 'should get one' do
    get :show, id: @stop, format: :json
    assert_response :success
    assert_valid response
  end
end
