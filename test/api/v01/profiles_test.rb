require 'test_helper'

class V01::ProfilesTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @profile = profiles(:profile_one)
    @current_customer = customers(:customer_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/profiles#{part}.json?api_key=testkey1"
  end

  def api_admin(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/profiles#{part}.json?api_key=adminkey"
  end

  test 'should return profiles' do
    get api_admin
    assert last_response.ok?, last_response.body
    assert_equal Profile.all.size, JSON.parse(last_response.body).size
  end

  test 'should not return profiles' do
    get api
    assert_equal 403, last_response.status, 'Bad response: ' + last_response.body
  end

  test 'should return routers in profile_one' do
    get api_admin(@profile.id.to_s + '/routers')
    assert last_response.ok?, last_response.body
    assert_equal @profile.routers.size, JSON.parse(last_response.body).size

    router_name = @profile.routers.first.name_locale[I18n.locale.to_s] || @profile.routers.first.name
    assert_equal router_name, JSON.parse(last_response.body)[0]['name']
  end

  test 'should not return routers' do
    get api(@profile.id.to_s + '/routers')
    assert_equal 403, last_response.status, 'Bad response: ' + last_response.body
  end

  test 'should return layers in profile_one' do
    get api_admin(@profile.id.to_s + '/layers')
    assert last_response.ok?, last_response.body
    assert_equal @profile.layers.size, JSON.parse(last_response.body).size
    assert_equal @profile.layers.first.name, JSON.parse(last_response.body)[0]['name']
  end

  test 'should not return layers' do
    get api(@profile.id.to_s + '/layers')
    assert_equal 403, last_response.status, 'Bad response: ' + last_response.body
  end
end
