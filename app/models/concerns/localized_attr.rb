module LocalizedAttr
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  #
  # Usage:
  # class Example < ActiveRecord::Base
  #   include LocalizedAttr
  #   attr_localized :value
  # end

  class_methods do
    def attr_localized(*names)
      names.each do |name|
        define_method("#{name}=") do |value|
          self[name] = value.is_a?(String) ? to_delocalized_decimal(value) : value
        end
        define_method("localized_#{name}") do
          return if send(name).nil?
          number_with_delimiter(("%g" % send(name)).gsub('.', I18n.t('number.format.separator')))
        end
      end
    end
  end

  def to_delocalized_decimal(value)
    delimiter = I18n.t('number.format.delimiter')
    separator = I18n.t('number.format.separator')
    value.gsub(separator, '.').gsub(/#{delimiter}([0-9]{3})/, '\1')
  end

end
