# Copyright © Mapotempo, 2016
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
class Serializable
  def self.dump(input)
    hash = input.is_a?(Hash) ? input : input.attributes
    hash = hash.compact
    hash.size > 0 ? hash : nil
  end

  def self.load(input)
    new(input)
  end

  def initialize(input)
    @hash = input || {}
  end

  def attributes
    @hash
  end

  def ==(other)
    @hash == other.attributes
  end

  def to_s
    @hash.to_s
  end

  def method_missing(method_sym, *arguments, &block)
    @hash.send(method_sym, *arguments, &block)
  end
end
