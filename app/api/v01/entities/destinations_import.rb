class V01::Entities::DestinationsImport < Grape::Entity
  def self.entity_name
    'V01_DestinationImport'
  end

  expose(:replace, documentation: { type: 'Boolean' })
  expose(:file, documentation: { type: Rack::Multipart::UploadedFile, desc: 'CSV file, encoding, separator and line return automatically detected, with localized CSV header according to HTTP header Accept-Language' })
end
