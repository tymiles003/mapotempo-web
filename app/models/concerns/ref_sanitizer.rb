module RefSanitizer
  extend ActiveSupport::Concern

  included do
    define_method "ref=" do |value|
      self[:ref] = value.strip if value
      if self.ref =~ /[\.\/\\]/
        record.errors[:ref] << I18n.t('activerecord.errors.models.planning.attributes.ref.invalid_format')
      end
    end
  end
end
