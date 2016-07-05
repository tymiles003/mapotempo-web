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

  attr_accessor :importer, :replace, :file, :delete_plannings, :column_def
  validates :file, presence: true
  validate :data

  def replace=(value)
    @replace = ValueToBoolean.value_to_boolean(value)
  end

  def delete_plannings=(value)
    @delete_plannings = ValueToBoolean.value_to_boolean(value)
  end

  def column_def=(values)
    @column_def = values.symbolize_keys
  end

  def name
    ((!file.original_filename.try(&:empty?) && file.original_filename) || (!file.filename.try(&:empty?) && file.filename)).try{ |s|
      s.split('.')[0..-2].join('.') if s.include?('.')
    }
  end

  def import(synchronous = false)
    if data
      begin
        last_row = nil
        Customer.transaction do
          @importer.import(data, name, synchronous, ignore_errors: false, replace: replace, delete_plannings: delete_plannings, line_shift: (without_header? ? 0 : 1), column_def: column_def) { |row|
            if row
              # Column Names: Strip Whitespaces
              row = row.each_with_object({}){ |(k, v), hash| hash[k.is_a?(String) ? k.strip : k] = v } if row.is_a? Hash

              # Switch from locale or custom to internal column name
              r, row = row, {}
              @importer.columns.each{ |k, v|
                if r.is_a?(Array)
                  values = ((column_def[k] && !column_def[k].empty?) ? column_def[k] : (without_header? ? '' : v[:title])).split(',').map{ |c|
                    if c.to_i != 0
                      r[c.to_i - 1].is_a?(Array) ? r[c.to_i - 1][1] : r[c.to_i - 1]
                    else
                      r.find{ |rr| rr[0] == c }.try{ |rr| rr[1] }
                    end
                  }.compact
                  row[k] = values.join(' ') if !values.empty?
                elsif r.key?(v[:title])
                  row[k] = r[v[:title]]
                end
              }
            end
            last_row = row

            row
          }
        end
      rescue => e
        errors[:base] << e.message + (last_row ? ' [' + last_row.to_a.collect{ |a| "#{a[0]}: \"#{a[1]}\"" }.join(', ') + ']' : '')
        Rails.logger.error e.backtrace.join("\n")
        return false
      end
    end
  end

  private

  def data
    @data ||= parse_csv
  end

  def without_header?
    column_def && !column_def.values.join('').empty? && column_def.values.all?{ |v| v.strip.empty? || v.split(',').all?{ |vv| vv.to_i != 0 } }
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

    if contents.blank?
      errors[:file] << I18n.t('destinations.import_file.empty_file')
      return false
    end

    line = contents.lines.first
    splitComma, splitSemicolon, splitTab = line.split(','), line.split(';'), line.split("\t")
    _split, separator = [[splitComma, ',', splitComma.size], [splitSemicolon, ';', splitSemicolon.size], [splitTab, "\t", splitTab.size]].max{ |a, b| a[2] <=> b[2] }

    begin
      column_def_any = column_def && column_def.values.any?{ |v| !v.strip.empty? }
      data = CSV.parse(contents, col_sep: separator, headers: !without_header?).collect{ |c|
        if column_def_any
          c.to_a
        else
          c.to_hash
        end
      }
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
