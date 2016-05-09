require 'optim/optimizer_wrapper'

class OptimizerWrapperTest < ActionController::TestCase
  setup do
    @optim = OptimizerWrapper.new(ActiveSupport::Cache::NullStore.new, 'http://localhost:1791/0.1/', 'demo')
  end

  test 'shoud optim' do
    m = [
      [[ 0,  0], [10, 10], [20, 20], [30, 30], [ 0,  0]],
      [[10, 10], [ 0,  0], [30, 30], [40, 40], [10, 10]],
      [[20, 20], [30, 30], [ 0,  0], [50, 50], [20, 20]],
      [[30, 30], [40, 40], [50, 50], [ 0,  0], [30, 30]],
      [[ 0,  0], [10, 10], [20, 20], [30, 30], [ 0,  0]],
    ]
    t = [
      {start: nil, end: nil, duration: 0},
      {start: nil, end: nil, duration: 0},
      {start: nil, end: nil, duration: 0},
      {start: nil, end: nil, duration: 0},
    ]

    assert_equal [0, 1, 2, 3, 4], @optim.optimize(m, 'time', t, [], nil, nil, nil)
  end

  test 'shoud optim, tw' do
    m = [
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
      [[ 1,  1], [ 0,  0], [ 1,  1], [10, 10], [ 1,  1]],
      [[ 1,  1], [ 1,  1], [ 0,  0], [10, 10], [ 1,  1]],
      [[10, 10], [10, 10], [10, 10], [ 0,  0], [10, 10]],
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
    ]
    t = [
      {start: nil, end: nil, duration: 0},
      {start: nil, end: nil, duration: 1},
      {start: nil, end: nil, duration: 0},
      {start: nil, end: nil, duration: 0},
    ]

    assert_equal [0, 1, 2, 3, 4], @optim.send(:unzip_cluster, [0, 1, 2, 3, 4], c, m, 0)
  end

  test 'shoud optim true case' do
    m = [
      [[0, 0], [655, 655], [1948, 1948], [5231, 5231], [2971, 2971], [0, 0]],
      [[603, 603], [0, 0], [1692, 1692], [4977, 4977], [2715, 2715], [603, 603]],
      [[1861, 1861], [1636, 1636], [0, 0], [6143, 6143], [1532, 1532], [1861, 1861]],
      [[5184, 5184], [4951, 4951], [6221, 6221], [0, 0], [7244, 7244], [5184, 5184]],
      [[2982, 2982], [2758, 2758], [1652, 1652], [7264, 7264], [0, 0], [2982, 2982]],
      [[0, 0], [655, 655], [1948, 1948], [5231, 5231], [2971, 2971], [0, 0]]]
    t = [
      {start: nil, end: nil, duration: 0},
      {start: nil, end: nil, duration: 1},
      {start: nil, end: nil, duration: 2},
      {start: nil, end: nil, duration: 3},
      {start: nil, end: nil, duration: 4},
    ]

    assert_equal [0, 1, 2, 3, 4, 5], @optim.send(:unzip_cluster, [0, 1, 2, 3, 4, 5], c, m, 0)
  end
end
