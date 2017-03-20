module TimeAttr
  extend ActiveSupport::Concern

  class_methods do
    def time_attr(*names)
      names.each do |name|
        define_method("#{name}_time") do
          integer_value = send(name)
          Time.at(integer_value).utc.strftime('%H:%M') if integer_value
        end

        define_method("#{name}_time_in_seconds") do
          integer_value = send(name)
          Time.at(integer_value).utc.strftime('%H:%M:%S') if integer_value
        end
      end
    end
  end

end
