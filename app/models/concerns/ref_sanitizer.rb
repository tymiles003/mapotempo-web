module RefSanitizer
  extend ActiveSupport::Concern

  included do
    validate do |record|
      if !record.ref.blank?
        record.ref.strip!
        if record.ref =~ %r{[\./\\]}
          record.errors[:ref] << I18n.t('activerecord.errors.models.planning.attributes.ref.invalid_format')
        end
      end
    end
  end
end
