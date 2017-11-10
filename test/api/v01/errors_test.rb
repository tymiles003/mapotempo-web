require 'test_helper'

class V01::ErrorTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
  end

  def api(part = nil, param = {}, format = 'json')
    part = part ? '/' + part.to_s : ''
    "/api/0.1/#{part}.#{format}?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return a 404 error in JSON format for route not found' do
    get api('not_found', {}, 'json')
    assert_equal 404, last_response.status, 'Bad response for JSON request: ' + last_response.body
    assert_equal 'application/json; charset=UTF-8', last_response.content_type, 'Bad content type for request: ' + last_response.body
  end

end
