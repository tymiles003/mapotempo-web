class ScheduleType < ActiveRecord::Type::Integer
  def type_cast(value)
    if value.kind_of?(Time) || value.kind_of?(DateTime)
        value.seconds_since_midnight.to_i
    elsif value.kind_of?(String)
      return nil if value.empty?
      integer_string = Integer(value) rescue false
      integer_string || Time.parse(value).seconds_since_midnight.to_i
    elsif value.kind_of?(Float)
      value.to_i
    else
      value
    end
  end
end
