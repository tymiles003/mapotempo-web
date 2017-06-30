class ScheduleType < ActiveRecord::Type::Integer
  def type_cast(value)
    if value.kind_of?(Time) || value.kind_of?(DateTime)
      value.seconds_since_midnight.to_i
    elsif value.kind_of?(String)
      raise ArgumentError.new(I18n.t('schedule_type.invalid')) if value !~ /\A[0-9: ]*\Z/

      return nil if value.empty?
      value = value + ':00' if value =~ /\A\d+:\d+\Z/
      ChronicDuration.parse(value, keep_zero: true)
    elsif value.kind_of?(Float) || value.kind_of?(ActiveSupport::Duration)
      value.to_i
    else
      value
    end
  end
end
