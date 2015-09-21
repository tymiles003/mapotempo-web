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

class Router < ActiveRecord::Base
  nilify_blanks
  auto_strip_attributes :name, :url
  validates :name, presence: true

  def isochrone?
    false
  end

  private

  def pack_vector(row, column)
    # Sort vector for caching
    i = -1
    row = row.map{ |a| [a[0], a[1], i += 1] }
    row = row.sort!{ |a, b|
      a[0] != b[0] ? a[0] <=> b[0] : a[1] <=> b[1]
    }

    i = -1
    column = column.map{ |a| [a[0], a[1], i += 1] }
    column = column.sort!{ |a, b|
      a[0] != b[0] ? a[0] <=> b[0] : a[1] <=> b[1]
    }

    [row, column]
  end

  def unpack_vector(row, column, matrix)
    # Restore original order
    out = []
    row.size.times{ |i|
      line = []
      column.size.times{ |j|
        line[column[j][2]] = matrix[i][j]
      }
      out[row[i][2]] = line
    }

    out
  end
end
