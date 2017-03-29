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
          ChronicDuration.output(integer_value, limit_to_hours: true, format: :chrono) if integer_value
          # Display hours and minutes only: units: 5
        end

        define_method("#{name}_time_with_seconds") do
          integer_value = send(name)
          Time.at(integer_value).utc.strftime('%H:%M:%S') if integer_value
        end

        define_method("#{name}_absolute_time_with_seconds") do
          integer_value = send(name)
          if integer_value
            value = ChronicDuration.output(integer_value, limit_to_hours: true, format: :chrono)
            value =~ /\A\d+:\d+\z/ ? "00:#{value}" : value
          end
          # Display hours and minutes only: units: 5
        end
      end
    end
  end

end
