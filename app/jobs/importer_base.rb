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

class ImportBaseError < StandardError; end
class ImportEmpty < ImportBaseError; end
class ImportInvalidRow < ImportBaseError; end
class ImportInvalidRef < ImportBaseError; end

class ImporterBase
  def initialize(customer)
    @customer = customer
    @warnings = []
  end

  def import(data, name, synchronous, options)
    @synchronous = synchronous
    dests = false
    refs = []

    Customer.transaction do
      before_import(name, data, options)

      dests = data.each_with_index.collect{ |row, line|
        # Switch from locale or custom to internal column name in case of csv
        row = yield(row)

        if row.empty?
          next # Skip empty line
        end

        begin
          #check the concat of ref and ref_visit json import
          ref = row[:ref].to_s + '|' + row[:ref_visit].to_s
          if (row[:ref] || row[:ref_visit]) && (refs.include?(ref))
            raise ImportInvalidRef.new(I18n.t('destinations.import_file.refs_duplicate', refs: ref))
          else
            refs.push(ref)
          end

          dest = import_row(name, row, line + 1 + (options[:line_shift] || 0), options)
          if dest.nil?
            next
          end

          if !@synchronous && Mapotempo::Application.config.delayed_job_use
            dest.delay_geocode
          end
          dest
        rescue ImportBaseError
          if options[:ignore_errors]
            @warnings << e if !@warnings.include?(e)
          else
            raise
          end
        end
      }
      raise ImportEmpty.new I18n.t('import.empty') if dests.all?(&:nil?)
      yield(nil)

      after_import(name, options)

      finalize_import(name, options)
    end

    dests
  end

  def warnings
    @warnings
  end
end
