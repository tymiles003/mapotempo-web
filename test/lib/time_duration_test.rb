class ExampleClass

  include TimeDuration
  has_time_duration [:field_name_start]

  def field_name_start
    return Time.utc(2000, 1, 1, 0, 0) + 20.minutes
  end
end

class TimeDurationTest < ActionController::TestCase
  setup do
    @model = ExampleClass.new
  end

  test "Should return numeric value in minutes by default" do
    assert_equal 20, @model.field_name_start_value
  end

  test "Should return numeric value in seconds" do
    assert_equal 20 * 60, @model.field_name_start_value(:seconds)
  end
end
