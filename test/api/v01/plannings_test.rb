require 'test_helper'

class V01::PlanningsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @planning = plannings(:planning_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=#{v}" }.join('&')
  end

  test 'should return customer''s plannings' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @planning.customer.plannings.size, JSON.parse(last_response.body).size
  end

  test 'should return a planning' do
    get api(@planning.id)
    assert last_response.ok?, last_response.body
    assert_equal @planning.name, JSON.parse(last_response.body)['name']
  end

  test 'should return a planning by ref' do
    get api("ref:#{@planning.ref}")
    assert last_response.ok?, last_response.body
    assert_equal @planning.ref, JSON.parse(last_response.body)['ref']
  end

  test 'should create a planning' do
    assert_difference('Planning.count', 1) do
      @planning.name = 'new name'
      post api(), @planning.attributes
      assert last_response.created?, last_response.body
    end
  end

  test 'should update a planning' do
    @planning.name = 'new name'
    put api(@planning.id), @planning.attributes
    assert last_response.ok?, last_response.body

    get api(@planning.id)
    assert last_response.ok?, last_response.body
    assert_equal @planning.name, JSON.parse(last_response.body)['name']
  end

  test 'should destroy a planning' do
    assert_difference('Planning.count', -1) do
      delete api(@planning.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should destroy multiple plannings' do
    assert_difference('Planning.count', -2) do
      delete api + "&ids[]=#{plannings(:planning_one).id}&ids[]=#{plannings(:planning_two).id}"
      assert last_response.ok?, last_response.body
    end
  end

  test 'should force recompute the planning after parameter update' do
    get api("#{@planning.id}/refresh")
    assert last_response.ok?, last_response.body
  end

#  test 'should switch two vehicles' do
#    patch api("#{@planning.id}/switch")
#    assert last_response.ok?, last_response.body
#  end

#  test 'should suggest a place for an unaffected stop' do
#    patch api("#{@planning.id}/automatic_insert")
#    assert last_response.ok?, last_response.body
#  end

#  test 'should set stop status' do
#    patch api("#{@planning.id}/update_stop")
#    assert last_response.ok?, last_response.body
#  end

#  test 'should starts asynchronous route optimization' do
#    get api("#{@planning.id}/optimize_route")
#    assert last_response.ok?, last_response.body
#  end

  test 'should change stops activation' do
    patch api("#{@planning.id}/routes/#{@planning.routes[1].id}/active/all")
    assert last_response.ok?, last_response.body
    patch api("#{@planning.id}/routes/#{@planning.routes[1].id}/active/reverse")
    assert last_response.ok?, last_response.body
  end

  test 'should clone planning' do
    assert_difference('Planning.count', 1) do
      patch api("#{@planning.id}/duplicate")
      assert last_response.ok?, last_response.body
    end
  end

  test 'should apply orders' do
    assert @planning.routes[1].stops[0].active
    assert @planning.routes[1].stops[1].active
    @order_array = order_arrays(:order_array_one)
    patch api("#{@planning.id}/orders/#{@order_array.id}/0")

    @planning.reload
    assert @planning.routes[1].stops[0].active
    assert_not @planning.routes[1].stops[1].active
  end
end
