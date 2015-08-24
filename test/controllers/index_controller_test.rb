require 'test_helper'

class IndexControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
  end

  test 'should get index' do
    get :index
    assert_response :success
  end
end
