# Copyright © Mapotempo, 2013-2015
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

class ImportCsv
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment
  extend ActiveModel::Translation

  attr_accessor :importer, :replace, :file, :delete_plannings
  validates :file, presence: true
  validate :data

  def replace=(value)
    @replace = ValueToBoolean.value_to_boolean(value)
  end

  def delete_plannings=(value)
    @delete_plannings = ValueToBoolean.value_to_boolean(value)
  end

  def name
    (file.original_filename || file.filename).split('.')[0..-2].join('.')
  end

  def import(synchronous = false)
    if data
      begin
        Customer.transaction do
          @importer.import(data, name, synchronous, ignore_errors: false, replace: replace, delete_plannings: delete_plannings) { |row|
            # Switch from locale to internal column name
            r, row = row, {}
            @importer.columns.each{ |k, v|
              if r.key?(v)
                row[k] = r[v]
              end
            }

            row
          }
        end
      rescue ImportBaseError => e
        errors[:base] << e.message
        return false
      end
    end
  end

  private

  def data
    @data ||= parse_csv
  end

  def parse_csv
    if !file
      return false
    end

    contents = File.open(file.tempfile, 'r:bom|utf-8').read
    if !contents.valid_encoding?
      detection = CharlockHolmes::EncodingDetector.detect(contents)
      if !contents || !detection[:encoding]
        errors[:file] << I18n.t('destinations.import_file.not_csv')
        return false
      end
      contents = CharlockHolmes::Converter.convert(contents, detection[:encoding], 'UTF-8')
    end

    line = contents.lines.first
    splitComma, splitSemicolon, splitTab = line.split(','), line.split(';'), line.split("\t")
    _split, separator = [[splitComma, ',', splitComma.size], [splitSemicolon, ';', splitSemicolon.size], [splitTab, "\t", splitTab.size]].max{ |a, b| a[2] <=> b[2] }

    begin
      data = CSV.parse(contents, col_sep: separator, headers: true).collect(&:to_hash)
      if data.length > @importer.max_lines + 1
        errors[:file] << I18n.t('destinations.import_file.too_many_lines', n: @importer.max_lines)
        return false
      end
    rescue CSV::MalformedCSVError => e
      errors[:file] << e.message
      return false
    end

    data
  end
end
