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

  def initialize(customer)
    @customer = customer
    @warnings = []
  end

  def import(data, replace, name, synchronous, ignore_error)
    dests = false

    Customer.transaction do
      before_import(replace, name, synchronous)

      dests = data.each_with_index.collect{ |row, line|
        row = yield(row)

        if row.size == 0
          next # Skip empty line
        end

        begin
          dest = import_row(replace, name, row, line + 1)
          if dest.nil?
            next
          end

          if !synchronous && Mapotempo::Application.config.delayed_job_use
            dest.delay_geocode
          end
          dest
        rescue => e
          if ignore_error
            @warnings << e if !@warnings.include?(e)
          else
            raise
          end
        end
      }

      after_import(replace, name, synchronous)

      finalize_import(replace, name, synchronous)
    end

    dests
  end

  def warnings
    @warnings
  end
end
