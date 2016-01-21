# Copyright © Mapotempo, 2014-2016
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
class V01::Entities::DestinationsImport < Grape::Entity
  def self.entity_name
    'V01_DestinationImport'
  end

  expose(:replace, documentation: { type: 'Boolean' })
  expose(:file, documentation: { type: Rack::Multipart::UploadedFile, desc: 'CSV file, encoding, separator and line return automatically detected, with localized CSV header according to HTTP header Accept-Language.', param_type: 'form'})
  expose(:destinations, using: V01::Entities::DestinationImportJson, documentation: { type: V01::Entities::DestinationImportJson, is_array: true, desc: 'In mutual exclusion with CSV file upload and remote.', param_type: 'form'})
  expose(:remote, documentation: { type: String, values: [:tomtom] })
end
