require 'test_helper'

require 'optim/ort'

class OrtTest < ActionController::TestCase
  setup do
    @optim = Ort.new(ActiveSupport::Cache::NullStore.new, 'http://localhost:4567/0.1/optimize_tsptw')
  end

  test 'should optimize' do
    begin
      uri_template = Addressable::Template.new('http://localhost:4567/0.1/optimize_tsptw')
      stub_table = stub_request(:post, uri_template)
      .with(:body => {"data"=>"{\"matrix\":[[[0,0],[1,1],[1,1],[10,10],[0,0]],[[1,1],[0,0],[1,1],[10,10],[1,1]],[[1,1],[1,1],[0,0],[10,10],[1,1]],[[10,10],[10,10],[10,10],[0,0],[10,10]],[[0,0],[1,1],[1,1],[10,10],[0,0]]],\"time_window\":[[0,2147483647,null,null,0],[null,null,null,null,0],[null,null,null,null,0],[null,null,null,null,0]],\"rest_window\":[],\"optimize_time\":1,\"soft_upper_bound\":0,\"iterations_without_improvment\":100,\"initial_time_out\":3000,\"time_out_multiplier\":2}"})
      .to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/optimizer/ort.json').read)
      m = [
        [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
        [[ 1,  1], [ 0,  0], [ 1,  1], [10, 10], [ 1,  1]],
        [[ 1,  1], [ 1,  1], [ 0,  0], [10, 10], [ 1,  1]],
        [[10, 10], [10, 10], [10, 10], [ 0,  0], [10, 10]],
        [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
      ]
      t = [
        {start1: nil, end1: nil, start2: nil, end2: nil, duration: 0},
        {start1: nil, end1: nil, start2: nil, end2: nil, duration: 0},
        {start1: nil, end1: nil, start2: nil, end2: nil, duration: 0},
      ]
      assert_equal [0, 1, 2, 3, 4], @optim.optimize(m, 'time', t, [:start, :stop], [], 1, 0, 0)
    ensure
      remove_request_stub stub_table
    end
  end

  test 'shoud zip cluster' do
    m = [
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
      [[ 1,  1], [ 0,  0], [ 1,  1], [10, 10], [ 1,  1]],
      [[ 1,  1], [ 1,  1], [ 0,  0], [10, 10], [ 1,  1]],
      [[10, 10], [10, 10], [10, 10], [ 0,  0], [10, 10]],
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
    ]
    t = [
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
    ]

    a, b, c = @optim.send(:zip_cluster, m, 0, t, 5)

    assert_equal [
      [[ 0,  0], [10, 10], [ 1,  1], [ 0,  0]],
      [[10, 10], [ 0,  0], [10, 10], [10, 10]],
      [[ 1,  1], [10, 10], [ 0,  0], [ 1,  1]],
      [[ 0,  0], [10, 10], [ 1,  1], [ 0,  0]],
    ], a
    assert_equal [
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
    ], b

    assert_equal [0, 3, 2, 1, 4], @optim.send(:unzip_cluster, [0, 1, 2, 3], c, m, 0)
  end

  test 'shoud zip cluster with rest' do
    m = [
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
      [[ 1,  1], [ 0,  0], [ 1,  1], [10, 10], [ 1,  1]],
      [[ 1,  1], [ 1,  1], [ 0,  0], [10, 10], [ 1,  1]],
      [[10, 10], [10, 10], [10, 10], [ 0,  0], [10, 10]],
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
    ]
    t = [
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
      [1, 2, 1],
    ]

    a, b, c = @optim.send(:zip_cluster, m, 0, t, 5)

    assert_equal [
      [[ 0,  0], [10, 10], [ 1,  1], [ 0,  0]],
      [[10, 10], [ 0,  0], [10, 10], [10, 10]],
      [[ 1,  1], [10, 10], [ 0,  0], [ 1,  1]],
      [[ 0,  0], [10, 10], [ 1,  1], [ 0,  0]],
    ], a
    assert_equal [
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
    ], b

    assert_equal [0, 3, 2, 1, 4, 5], @optim.send(:unzip_cluster, [0, 1, 2, 3, 4], c, m, 0)
    assert_equal [0, 3, 2, 1, 5, 4], @optim.send(:unzip_cluster, [0, 1, 2, 4, 3], c, m, 0)
    assert_equal [0, 3, 5, 2, 1, 4], @optim.send(:unzip_cluster, [0, 1, 4, 2, 3], c, m, 0)
  end

  test 'shoud not zip cluster' do
    m = [
      [[ 0,  0], [10, 10], [20, 20], [30, 30], [ 0,  0]],
      [[10, 10], [ 0,  0], [30, 30], [40, 40], [10, 10]],
      [[20, 20], [30, 30], [ 0,  0], [50, 50], [20, 20]],
      [[30, 30], [40, 40], [50, 50], [ 0,  0], [30, 30]],
      [[ 0,  0], [10, 10], [20, 20], [30, 30], [ 0,  0]],
    ]
    t = [
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
    ]

    a, b, c = @optim.send(:zip_cluster, m, 0, t, 5)

    assert_equal m, a
    assert_equal b, t
    assert_equal [0, 1, 2, 3, 4], @optim.send(:unzip_cluster, [0, 1, 2, 3, 4], c, m, 0)
  end

  test 'shoud not zip cluster, tw' do
    m = [
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
      [[ 1,  1], [ 0,  0], [ 1,  1], [10, 10], [ 1,  1]],
      [[ 1,  1], [ 1,  1], [ 0,  0], [10, 10], [ 1,  1]],
      [[10, 10], [10, 10], [10, 10], [ 0,  0], [10, 10]],
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
    ]
    t = [
      [nil, nil, 0],
      [nil, nil, 1],
      [nil, nil, 0],
      [nil, nil, 0],
    ]
    a, b, c = @optim.send(:zip_cluster, m, 0, t, 5)

    assert_equal m, a
    assert_equal b, t
    assert_equal [0, 1, 2, 3, 4], @optim.send(:unzip_cluster, [0, 1, 2, 3, 4], c, m, 0)
  end

  test 'shoud not zip cluster true case' do
    m = [
      [[0, 0], [655, 655], [1948, 1948], [5231, 5231], [2971, 2971], [0, 0]],
      [[603, 603], [0, 0], [1692, 1692], [4977, 4977], [2715, 2715], [603, 603]],
      [[1861, 1861], [1636, 1636], [0, 0], [6143, 6143], [1532, 1532], [1861, 1861]],
      [[5184, 5184], [4951, 4951], [6221, 6221], [0, 0], [7244, 7244], [5184, 5184]],
      [[2982, 2982], [2758, 2758], [1652, 1652], [7264, 7264], [0, 0], [2982, 2982]],
      [[0, 0], [655, 655], [1948, 1948], [5231, 5231], [2971, 2971], [0, 0]]]
    t = [[nil, nil, 0], [nil, nil, 1], [nil, nil, 2], [nil, nil, 3], [nil, nil, 4]]

    a, b, c = @optim.send(:zip_cluster, m, 0, t, 5)

    assert_equal m, a
    assert_equal t, b
    assert_equal [0, 1, 2, 3, 4, 5], @optim.send(:unzip_cluster, [0, 1, 2, 3, 4, 5], c, m, 0)
  end

  test 'shoud zip cluster true case' do
    m = [
      [[0, 0], [693, 693], [655, 655], [1948, 1948], [693, 693], [0, 0]],
      [[609, 609], [0, 0], [416, 416], [2070, 2070], [0, 0], [609, 609]],
      [[603, 603], [489, 489], [0, 0], [1692, 1692], [489, 489], [603, 603]],
      [[1861, 1861], [1933, 1933], [1636, 1636], [0, 0], [1933, 1933], [1861, 1861]],
      [[609, 609], [0, 0], [416, 416], [2070, 2070], [0, 0], [609, 609]],
      [[0, 0], [693, 693], [655, 655], [1948, 1948], [693, 693], [0, 0]]]
    t = [[nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0]]

    a, b, c = @optim.send(:zip_cluster, m, 0, t, 5)

    assert_equal [
      [[0, 0], [655, 655], [1948, 1948], [693, 693], [0, 0]],
      [[603, 603], [0, 0], [1692, 1692], [489, 489], [603, 603]],
      [[1861, 1861], [1636, 1636], [0, 0], [1933, 1933], [1861, 1861]],
      [[609, 609], [416, 416], [2070, 2070], [0, 0], [609, 609]],
      [[0, 0], [655, 655], [1948, 1948], [693, 693], [0, 0]]], a
    assert_equal [[nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0]], b
    assert_equal [0, 2, 3, 4, 1, 5], @optim.send(:unzip_cluster, [0, 1, 2, 3, 4], c, m, 0)
  end

  test 'shoud zip large cluster case' do
    m = [
      [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7]],
      [[1, 1], [0, 0], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7]],
      [[1, 1], [2, 2], [0, 0], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7]],
      [[1, 1], [2, 2], [3, 3], [0, 0], [4, 4], [5, 5], [6, 6], [7, 7]],
      [[1, 1], [2, 2], [3, 3], [4, 4], [0, 0], [5, 5], [6, 6], [7, 7]],
      [[1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [0, 0], [6, 6], [7, 7]],
      [[1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [0, 0], [7, 7]],
      [[1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [0, 0]]]
    t = [[nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0]]

    a, b, c = @optim.send(:zip_cluster, m, 0, t, 100)

    assert_equal [
      [[0, 0], [2, 2], [7, 7]],
      [[1, 1], [0, 0], [7, 7]],
      [[1, 1], [3, 3], [0, 0]]], a
    assert_equal [[nil, nil, 0], [nil, nil, 0]], b
    suppress_output { assert_equal m.size, @optim.send(:unzip_cluster, [0, 1, 2], c, m, 0).size }
  end
end
