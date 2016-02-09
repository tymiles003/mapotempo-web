# Copyright © Mapotempo, 2015
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
require 'value_to_boolean'

class ImportTomtom
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment
  extend ActiveModel::Translation

  attr_accessor :importer, :replace, :customer

  def replace=(value)
    @replace = ValueToBoolean.value_to_boolean(value)
  end

  def import(synchronous = false)
    begin
      Customer.transaction do
        address = Mapotempo::Application.config.tomtom.showAddressReport(@customer.tomtom_account, @customer.tomtom_user, @customer.tomtom_password)
        @importer.import(address, nil, synchronous, ignore_errors: true, replace: replace) { |row|
          if !row[:tags].nil?
            row[:tags] = row[:tags].join(',')
          end

          row
        }
      end
    rescue ImportBaseError => e
      errors[:base] << e.message
      return false
    end
  end

  def warnings
    @importer.warnings
  end
end
