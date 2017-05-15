require 'test_helper'

class V01::StopsTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @stop = stops(:stop_one_one)
  end

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |url, mode, dimension, segments, options| segments.collect{ |i| [1000, 60, '_ibE_seK_seK_seK'] } } ) do
      yield
    end
  end

  def api(planning_id, route_id, part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/plannings/#{planning_id}/routes/#{route_id}/stops#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return customer''s routes' do
    put api(@stop.route.planning.id, @stop.route.id, @stop.id)
    assert_equal 204, last_response.status, last_response.body
  end

  test 'should move stop position in routes' do
    patch api(@stop.route.planning.id, @stop.route.id, "#{@stop.route.planning.routes[0].stops[0].id}/move/1")
    assert_equal 204, last_response.status, last_response.body
  end
end
