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
require 'csv'

class ImporterBase

  def self.import_csv(replace, customer, file, name, synchronous=false)
    contents = File.open(file, 'r:bom|utf-8').read
    if !contents.valid_encoding?
      detection = CharlockHolmes::EncodingDetector.detect(contents)
      if !contents || !detection[:encoding]
        raise I18n.t('destinations.import_file.not_csv')
      end
      contents = CharlockHolmes::Converter.convert(contents, detection[:encoding], 'UTF-8')
    end

    separator = ','
    line = contents.lines.first
    splitComma, splitSemicolon, splitTab = line.split(','), line.split(';'), line.split("\t")
    _split, separator = [[splitComma, ',', splitComma.size], [splitSemicolon, ';', splitSemicolon.size], [splitTab, "\t", splitTab.size]].max{ |a, b| a[2] <=> b[2] }

    data = CSV.parse(contents, col_sep: separator, headers: true).collect(&:to_hash)

    self.import(replace, customer, data, name, synchronous) { |row|
      # Switch from locale to internal column name
      r, row = row, {}
      columns.each{ |k, v|
        if r.key?(v) && r[v]
          row[k] = r[v]
        end
      }

      row
    }
  end

  def self.import_hash(replace, customer, data)
    key = %w(ref route name street detail postalcode city lat lng open close comment tags take_over quantity active)

    self.import(replace, customer, data, nil, true) { |row|
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

end
