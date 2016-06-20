require 'optim/optimizer_wrapper'

class OptimizerWrapperTest < ActionController::TestCase
  setup do
    @optim = OptimizerWrapper.new(ActiveSupport::Cache::NullStore.new, 'http://localhost:1791/0.1', 'demo')

    uri_template = Addressable::Template.new('localhost:1791/0.1/vrp/submit.json')
    @stub_VrpSubmit = stub_request(:post, uri_template).to_return(File.new(File.expand_path('../../../', __FILE__) + '/fixtures/optimizer-wrapper/vrp-submit.json').read)

    uri_template = Addressable::Template.new('http://localhost:1791/0.1/vrp/job/{job_id}.json?api_key={api_key}')
    @stub_VrpJob = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../../../', __FILE__) + '/fixtures/optimizer-wrapper/vrp-job.json').read)
  end

  def teardown
    remove_request_stub(@stub_VrpJob)
    remove_request_stub(@stub_VrpSubmit)
  end

  test 'shoud optimize' do
    m = [
      [[0, 0], [655, 655], [1948, 1948], [5231, 5231], [2971, 2971], [0, 0]],
      [[603, 603], [0, 0], [1692, 1692], [4977, 4977], [2715, 2715], [603, 603]],
      [[1861, 1861], [1636, 1636], [0, 0], [6143, 6143], [1532, 1532], [1861, 1861]],
      [[5184, 5184], [4951, 4951], [6221, 6221], [0, 0], [7244, 7244], [5184, 5184]],
      [[2982, 2982], [2758, 2758], [1652, 1652], [7264, 7264], [0, 0], [2982, 2982]],
      [[0, 0], [655, 655], [1948, 1948], [5231, 5231], [2971, 2971], [0, 0]]]
    t = [
      {start1: nil, end1: nil, start2: nil, end2: nil, duration: 300.0},
      {start1: nil, end1: nil, start2: nil, end2: nil, duration: 300.0},
      {start1: 28800, end1: 36000, start2: nil, end2: nil, duration: 500.0},
      {start1: 0, end1: 7200, start2: nil, end2: nil, duration: 300.0},
    ]
    r = [
      {start: 28800, end: 36000, duration: 500.0},
    ]

    assert_equal [0, 1, 2, 3, 4, 6, 5], @optim.optimize(m, 'time', t, [:start, :stop], r, nil, nil, nil)

    assert_equal [0, 1, 2, 3, 4, 6, 5], @optim.optimize(m, 'time', t, [:start], r, nil, nil, nil)

    assert_equal [0, 1, 2, 3, 4, 6, 5], @optim.optimize(m, 'time', t, [], r, nil, nil, nil)
  end
end
