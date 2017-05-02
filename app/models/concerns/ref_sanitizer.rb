module RefSanitizer
  extend ActiveSupport::Concern

  included do
    validate do |record|
      unless record.ref.blank?
        record.ref.strip!
        if record.ref =~ %r{[\./\\]}
          record.errors.add(:ref, I18n.t('activerecord.errors.models.planning.attributes.ref.invalid_format'))
        end
      end
    end

    def self.human_attribute_name(attr, l = {})
      attr.to_s == 'routes.ref' ? I18n.t('activerecord.errors.models.planning.attributes.ref.ref_value') : super
    end
  end
end
