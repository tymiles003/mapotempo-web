require 'test_helper'

class V01::RoutesTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @route = routes(:route_one)
  end

  def api(destination_id, part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings/#{destination_id}/routes#{part}.json?api_key=testkey1"
  end

  test 'should return customer''s routes' do
    get api(@route.planning.id)
    assert last_response.ok?, last_response.body
    assert_equal @route.planning.routes.size, JSON.parse(last_response.body).size
  end

  test 'should return a route' do
    get api(@route.planning.id, @route.id)
    assert last_response.ok?, last_response.body
    assert @route.stops.size, JSON.parse(last_response.body)['stops'].size
  end

  test 'should update a route' do
    @route.locked = true
    put api(@route.planning.id, @route.id), @route.attributes
    assert last_response.ok?, last_response.body

    get api(@route.planning.id, @route.id)
    assert last_response.ok?, last_response.body
    assert_equal @route.locked, JSON.parse(last_response.body)['locked']
  end

  test 'should move destination position in routes' do
    patch api(@route.planning.id, "#{@route.id}/destinations/#{@route.planning.routes[0].stops[0].destination.id}/move/1"), @route.attributes
    assert last_response.ok?, last_response.body
  end

  test 'should change stops activation' do
    patch api(@route.planning.id, "#{@route.id}/active/reverse")
    assert last_response.ok?, last_response.body
  end

  test 'should move destination position in routes by refs' do
    patch api("ref:#{@route.planning.ref}", "ref:#{@route.ref}/destinations/ref:#{@route.planning.routes[0].stops[0].destination.ref}/move/1"), @route.attributes
    assert last_response.ok?, last_response.body
  end
end
