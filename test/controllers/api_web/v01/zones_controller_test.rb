require 'test_helper'

class ApiWeb::V01::ZonesControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @zone = zones(:zone_one)
    sign_in users(:user_one)
  end

  test 'should get zones' do
    get :index, zoning_id: @zone.zoning_id
    assert_response :success
  end
end
