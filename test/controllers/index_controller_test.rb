require 'test_helper'

class IndexControllerTest < ActionController::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should get index" do
    get :index
    assert_response :success
  end

end
