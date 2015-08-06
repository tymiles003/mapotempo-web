require 'test_helper'

class V01::RoutesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    def Osrm.compute(url, from_lat, from_lng, to_lat, to_lng)
      [1000, 60, "trace"]
    end

    def Ort.optimize(optimize_time, soft_upper_bound, capacity, matrix, time_window, time_window_rest, time_threshold)
      (0..(matrix.size-1)).to_a
    end

    @route = routes(:route_one)
  end

  def api(planning_id, part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings/#{planning_id}/routes#{part}.json?api_key=testkey1"
  end

  test 'should return customer''s routes' do
    get api(@route.planning.id)
    assert last_response.ok?, last_response.body
    assert_equal @route.planning.routes.size, JSON.parse(last_response.body).size
  end

  test 'should return a route' do
    get api(@route.planning.id, @route.id)
    assert last_response.ok?, last_response.body
    stops = JSON.parse(last_response.body)['stops']
    assert_equal @route.stops.size, stops.size
    assert_equal '2015-10-10T00:00:30', stops[0]['time']
  end

  test 'should update a route' do
    @route.locked = true
    put api(@route.planning.id, @route.id), @route.attributes
    assert last_response.ok?, last_response.body

    get api(@route.planning.id, @route.id)
    assert last_response.ok?, last_response.body
    assert_equal @route.locked, JSON.parse(last_response.body)['locked']
  end

  test 'should move stop position in routes' do
    patch api(@route.planning.id, "#{@route.id}/stops/#{@route.planning.routes[0].stops[0].id}/move/1")
    assert last_response.ok?, last_response.body
  end

  test 'should change stops activation' do
    patch api(@route.planning.id, "#{@route.id}/active/reverse")
    assert last_response.ok?, last_response.body
  end

  test 'should move destinations in routes' do
    patch api(@route.planning.id, "#{@route.id}/destinations/moves"), destination_ids: [destinations(:destination_one).id, destinations(:destination_two).id]
    assert last_response.ok?, last_response.body
  end

  test 'should optimize route' do
    patch api(@route.planning.id, "#{@route.id}/optimize")
    assert_equal 204, last_response.status, last_response.body
  end
end
