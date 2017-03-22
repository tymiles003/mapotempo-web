class ScheduleType < ActiveRecord::Type::Integer
  def type_cast(value)
    if value.kind_of?(Time) || value.kind_of?(DateTime)
        value.seconds_since_midnight.to_i
    elsif value.kind_of?(String)
      return nil if value.empty?
      value = value + ':00' if value =~ /\A\d+:\d+\Z/
      ChronicDuration.parse(value)
    elsif value.kind_of?(Float) || value.kind_of?(ActiveSupport::Duration)
      value.to_i
    else
      value
    end
  end
end
