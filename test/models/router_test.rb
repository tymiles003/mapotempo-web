require 'test_helper'
require 'osrm'

class RouterTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def around
    Osrm.stub_any_instance(:matrix, lambda{ |url, vector| Array.new(vector.size, Array.new(vector.size, 0)) }) do
      Here.stub_any_instance(:matrix, lambda{ |row, column| Array.new(row.size, Array.new(column.size, [0, 0])) }) do
        yield
      end
    end
  end

  test 'should pack and unpack sorted vector' do
    router = routers(:router_one)
    r = [[1, 1], [2, 2]]
    c = [[3, 3], [4, 4], [5, 5]]
    ar, ac = router.send(:pack_vector, r, c)
    assert_equal [[1, 1, 0], [2, 2, 1]], ar
    assert_equal [[3, 3, 0], [4, 4, 1], [5, 5, 2]], ac
    m = [[1, 2, 3], [4, 5, 6]]
    am = router.send(:unpack_vector, ar, ac, m)
    assert_equal m, am
  end

  test 'should pack and unpack reverse vector' do
    router = routers(:router_one)
    r = [[2, 2], [1, 1]]
    c = [[5, 5], [4, 4], [3, 3]]
    ar, ac = router.send(:pack_vector, r, c)
    assert_equal [[1, 1, 1], [2, 2, 0]], ar
    assert_equal [[3, 3, 2], [4, 4, 1], [5, 5, 0]], ac
    m = [[1, 2, 3], [4, 5, 6]]
    am = router.send(:unpack_vector, ar, ac, m)
    assert_equal [[6, 5, 4], [3, 2, 1]], am
  end

  test 'should compute matrix with OSRM' do
    router = routers(:router_osrm)
    row = [[47.3174, 5.0336]]
    column = [[45.750569, 4.839445], [45.763661, 4.851408], [45.755932, 4.850413]]
    matrix = router.matrix(row, column, 1)
    assert_equal 1, matrix.size
    assert_equal 3, matrix[0].size
  end

  test 'should compute matrix with HERE' do
    router = routers(:router_here)
    row = [[47.3174, 5.0336]]
    column = [[45.750569, 4.839445], [45.763661, 4.851408], [45.755932, 4.850413]]
    matrix = router.matrix(row, column, 1)
    assert_equal 1, matrix.size
    assert_equal 3, matrix[0].size
  end
end
