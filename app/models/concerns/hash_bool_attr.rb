module HashBoolAttr
  extend ActiveSupport::Concern
  require 'value_to_boolean'

  class_methods do
    def hash_bool_attr(hash, *names)
      names.each do |name|
        define_method(name) do
          original_value = send(hash)[name.to_s]
          return ValueToBoolean.value_to_boolean(original_value)
        end

        define_method("#{name}?") do
          original_value = send(hash)[name.to_s]
          return ValueToBoolean.value_to_boolean(original_value)
        end
      end
    end
  end
end
