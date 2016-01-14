require 'active_support/concern'

module TimeDuration
  extend ActiveSupport::Concern

  included do
    # Return duration in minutes, default to 0
    def self.has_time_duration field_names
      field_names.each do |name|
        define_method "#{name}_value" do |time_value = :minutes|
          return 0 if !send(name)
          return ((send(name) - Time.utc(2000, 1, 1, 0, 0)) / 1.send(time_value.to_s.singularize).seconds).to_i
        end
      end
    end
  end
end
