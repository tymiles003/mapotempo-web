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

class ImportJson
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment
  extend ActiveModel::Translation

  attr_accessor :importer, :replace, :json

  def replace=(value)
    @replace = ValueToBoolean.value_to_boolean(value)
  end

  def import(synchronous = false)
    if json
      begin
        Customer.transaction do
          key = %w(ref route name street detail postalcode city lat lng open close comment tags take_over quantity active)

          @importer.import(json, replace, nil, synchronous, false) { |row|
            r, row = row, {}
            r.each{ |k, v|
              if key.include?(k)
                row[k.to_sym] = v
              end
            }

            if !row[:tags].nil?
              row[:tags] = row[:tags].join(',')
            end

            row
          }
        end
      rescue => e
        errors[:base] << e.message
        return false
      end
    end
  end
end
