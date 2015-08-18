require 'osrm'

class OsrmTest < ActionController::TestCase
  setup do
    @osrm = Mapotempo::Application.config.osrm
    @customer = customers(:customer_one)
  end

  test "should compute matrix" do
    matrix = @osrm.matrix(routers(:router_one).url, [[45.750569, 4.839445], [45.763661, 4.851408], [45.755932, 4.850413]])
    assert_equal 3, matrix.size
    assert_equal 3, matrix[0].size
  end

  test "should compute matrix on impassable" do
    impassable = @osrm.compute(routers(:router_one).url, 46.63487, 2.54804, 42.161697, 9.138183)
    assert_not impassable[2] # no trace

    matrix = @osrm.matrix(routers(:router_one).url, [[46.634056, 2.547283], [42.161697, 9.138183]])
  end

  test "should compute large matrix" do
    SIZE = 110
    prng = Random.new
    vector = SIZE.times.collect{ [prng.rand(48.811159..48.911218), prng.rand(2.270393..2.435532)] } # Some points in Paris
    #start = Time.now
    matrix = @osrm.matrix(routers(:router_one).url, vector)
    #finish = Time.now
    #puts finish - start

    assert_equal SIZE, matrix.size
    assert_equal SIZE, matrix[0].size
  end
end
