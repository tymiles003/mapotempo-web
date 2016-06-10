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

class ImportBaseError < StandardError ; end
class ImportEmpty < ImportBaseError ; end
class ImportInvalidRow < ImportBaseError ; end

class ImporterBase

  def initialize(customer)
    @customer = customer
    @warnings = []
  end

  def import(data, name, synchronous, options)
    @synchronous = synchronous
    dests = false

    Customer.transaction do
      before_import(name, options)

      dests = data.each_with_index.collect{ |row, line|
        row = yield(row)

        if row.size == 0
          next # Skip empty line
        end

        begin
          dest = import_row(name, row, line + 1 + (options[:line_shift] || 0), options)
          if dest.nil?
            next
          end

          if !@synchronous && Mapotempo::Application.config.delayed_job_use
            dest.delay_geocode
          end
          dest
        rescue ImportBaseError => e
          if options[:ignore_errors]
            @warnings << e if !@warnings.include?(e)
          else
            raise
          end
        end
      }
      raise ImportEmpty.new I18n.t('import.empty') if dests.all? &:nil?
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
