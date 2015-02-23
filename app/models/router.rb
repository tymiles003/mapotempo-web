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
  validates :name, presence: true

  private

  def pack_vector(vector)
    # Sort vector for caching
    i = -1
    vector = vector.map{ |a| [a[0], a[1], i += 1] }
    vector.sort!{ |a, b|
      a[0] != b[0] ? a[0] <=> b[0] : a[1] <=> b[1]
    }
  end

  def unpack_vector(vector, matrix)
    # Restore original order
    size = vector.size
    column = []
    size.times{ |i|
      line = []
      size.times{ |j|
        line[vector[j][2]] = matrix[i][j]
      }
      column[vector[i][2]] = line
    }

    column
  end
end
