require 'here'

class HereTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
  end

  test "should compute route" do
    trace = Here.compute(45.750569, 4.839445, 45.763661, 4.851408)
    assert trace
  end

  test "should compute matrix" do
    matrix = Here.matrix([[45.750569, 4.839445], [45.763661, 4.851408], [45.755932, 4.850413]])
    assert_equal 3, matrix.size
    assert_equal 3, matrix[0].size
  end

#  test "should compute large matrix" do
#    SIZE = 100
#    prng = Random.new
#    vector = SIZE.times.collect{ [prng.rand(48.811159..48.911218), prng.rand(2.270393..2.435532)] } # Some points in Paris
#    #start = Time.now
#    matrix = Here.matrix(vector)
#    #finish = Time.now
#    #puts finish - start
#
#    assert_equal SIZE, matrix.size
#    assert_equal SIZE, matrix[0].size
#  end
end
