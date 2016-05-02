require 'routers/router_wrapper'

class Routers::RouterWrapperTest < ActionController::TestCase
  setup do
    @router_wrapper = Mapotempo::Application.config.router_wrapper
    @customer = customers(:customer_one)
  end

  test 'should compute route' do
    begin
      points = [[44.82641, -0.55674], [44.83, -0.557]]

      uri_template = Addressable::Template.new('http://localhost:4899/0.1/routes.json')
      stub_route = stub_request(:post, uri_template).with(body: hash_including({dimension: 'time', locs: points.flatten.join(',')})).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/router_wrapper/routes.json'))

      route = @router_wrapper.compute_batch(routers(:router_wrapper_public_transport).url_time, :public_transport, :time, [points.flatten])
      assert !route[0][2].nil? # trace
    ensure
      remove_request_stub(stub_route)
    end
  end

  test 'should compute matrix' do
    begin
      points = [[44.82641, -0.55674], [44.83, -0.557], [44.822, -0.554]]

      uri_template = Addressable::Template.new('http://localhost:4899/0.1/matrix.json')
      stub_matrix = stub_request(:post, uri_template).with(body: hash_including(dimension: 'time', src: points.flatten.join(','))).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/router_wrapper/matrix.json'))

      matrix = @router_wrapper.matrix(routers(:router_wrapper_public_transport).url_time, :public_transport, :time, points, points)
      assert_equal 3, matrix.size
      assert_equal 3, matrix[0].size
    ensure
      remove_request_stub(stub_matrix)
    end
  end

  test 'should compute matrix on impassable' do
    begin
      points = [[46.634056, 2.547283], [42.161697, 9.138183]]

      uri_template = Addressable::Template.new('http://localhost:4899/0.1/routes.json')
      stub_route = stub_request(:post, uri_template).with(body: hash_including(dimension: 'time', locs: points.flatten.join(','))).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/router_wrapper/routes-impassable.json'))
      uri_template = Addressable::Template.new('http://localhost:4899/0.1/matrix.json')
      stub_matrix = stub_request(:post, uri_template).with(body: hash_including(dimension: 'time', src: points.flatten.join(','))).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/router_wrapper/matrix-impassable.json'))

      impassable = @router_wrapper.compute_batch(routers(:router_wrapper_public_transport).url_time, :public_transport, :time, [points.flatten])
      assert_not impassable && impassable.size > 0 && impassable[0][2] # no trace

      matrix = @router_wrapper.matrix(routers(:router_wrapper_public_transport).url_time, :public_transport, :time, points, points)
    ensure
      remove_request_stub(stub_route)
      remove_request_stub(stub_matrix)
    end
  end

  test 'should compute isoline' do
    begin
      point = [44.82641, -0.55674]

      uri_template = Addressable::Template.new('http://localhost:4899/0.1/isoline.json')
      stub_isoline = stub_request(:post, uri_template).with(body: hash_including(dimension: 'time', loc: point.flatten.join(','))).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/router_wrapper/isoline.json'))

      isoline = @router_wrapper.isoline(routers(:router_wrapper_public_transport).url_time, :public_transport, :time, point[0], point[1], 120)
      assert isoline['features'].size > 0
    ensure
      remove_request_stub(stub_isoline)
    end
  end
end
