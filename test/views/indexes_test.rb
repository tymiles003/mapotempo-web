require 'test_helper'

class IndexesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include Rails.application.routes.url_helpers

  def app
    Rails.application
  end

  test 'should redirect to sign in page if key is invalid' do
    get '/?api_key=bad_key'

    assert last_response.status, 302
    assert_match /text\/html/, last_response.content_type
    assert_match /#{new_user_session_path}/, last_response.location
  end

  test 'should display the requested page if key is valid' do
    get '/?api_key=testkey1'

    assert last_response.status, 200
  end
end
