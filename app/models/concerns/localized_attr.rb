module LocalizedAttr
  extend ActiveSupport::Concern

  class_methods do
    def attr_localized *fields
      fields.each do |field|
        define_method("#{field}=") do |value|
          self[field] = value.is_a?(String) ? to_delocalized_decimal(value) : value
        end
      end
    end
  end

  def to_delocalized_decimal value
    delimiter = I18n::t('number.format.delimiter')
    separator = I18n::t('number.format.separator')
    value.gsub("#{separator}", '.').gsub(/#{delimiter}([0-9]{3})/, '\1')
  end
end
