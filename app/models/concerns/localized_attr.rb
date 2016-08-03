module LocalizedAttr
  extend ActiveSupport::Concern

  class_methods do
    include ActionView::Helpers::NumberHelper

    def attr_localized(*names)
      names.each do |name|
        define_method("#{name}=") do |value|
          self[name] = value.is_a?(String) ? self.class.to_delocalized_decimal(value) : value
        end
        define_method("localized_#{name}") do
          return if !send(name)
          self.class.localize_numeric_value send(name)
        end
      end
    end
    def to_delocalized_decimal(value)
      delimiter = I18n.t('number.format.delimiter')
      separator = I18n.t('number.format.separator')
      value.gsub(separator, '.').gsub(/#{delimiter}([0-9]{3})/, '\1')
    end
    def localize_numeric_value(value)
      number_with_delimiter ("%g" % value).gsub('.', I18n.t('number.format.separator'))
    end
  end

end
