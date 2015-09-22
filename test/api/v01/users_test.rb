require 'test_helper'

class V01::UsersTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @user = users(:user_two)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/users#{part}.json?api_key=testkey1"
  end

  def api_admin(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/users#{part}.json?api_key=adminkey"
  end

  test 'should return users' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @user.customer.users.size, JSON.parse(last_response.body).size
  end

  test 'should return a user' do
    get api(@user.id)
    assert last_response.ok?, last_response.body
    assert_equal @user.email, JSON.parse(last_response.body)['email']
  end

  test 'should create a user' do
    assert_difference('User.count', 1) do
      # use a new hash here instead of @user.attributes to be able to send password
      post api_admin(), {email: 'new@plop.com', password: 'password', customer_id: @user.customer_id, layer_id: @user.layer_id}
      assert last_response.created?, last_response.body
    end
  end

  test 'should update a user' do
    @user.email = 'updated@plop.com'
    put api_admin(@user.id), @user.attributes
    assert last_response.ok?, last_response.body

    get api_admin(@user.id)
    assert last_response.ok?, last_response.body
    assert_equal @user.email, JSON.parse(last_response.body)['email']
  end

  test 'should destroy a user' do
    assert_difference('User.count', -1) do
      delete api_admin(@user.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should destroy multiple users' do
    assert_difference('User.count', -2) do
      delete api_admin + "&ids=#{users(:user_one).id},#{users(:user_two).id}"
      assert last_response.ok?, last_response.body
    end
  end
end
