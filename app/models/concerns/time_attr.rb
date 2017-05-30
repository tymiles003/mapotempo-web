module TimeAttr
  extend ActiveSupport::Concern

  class_methods do
    def time_attr(*names)
      names.each do |name|
        define_method("#{name}_time") do
          integer_value = send(name)
          Time.at(integer_value).utc.strftime('%H:%M') if integer_value
        end

        define_method("#{name}_absolute_time") do
          integer_value = send(name)
          # ChronicDuration is used for time over 24 hours
          # Display hours and minutes only: units: 5
          if integer_value
            if integer_value == 0
              '00:00'
            else
              hour_value = ChronicDuration.output(integer_value, limit_to_hours: true, format: :chrono, units: 5)
              hour_value.length < 5 ? '00:00'[0..4 - hour_value.length] + hour_value : hour_value
            end
          end
        end

        define_method("#{name}_time_with_seconds") do
          integer_value = send(name)
          Time.at(integer_value).utc.strftime('%H:%M:%S') if integer_value
        end

        define_method("#{name}_absolute_time_with_seconds") do
          integer_value = send(name)
          if integer_value
            hour_value = ChronicDuration.output(integer_value, limit_to_hours: true, format: :chrono)
            hour_value.length < 8 ? '00:00:00'[0..7 - hour_value.length] + hour_value : hour_value
          end
        end
      end
    end
  end

end
