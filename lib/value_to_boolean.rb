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

class ValueToBoolean
  @@true_values = [true, 1, '1', 't', 'true', 'on', 'yes'].to_set.freeze

  # convert something to a boolean
  def self.value_to_boolean(value, default = false)
    if value.nil? || (value.is_a?(String) && value.empty?)
      default
    else
      val = value.is_a?(String) ? value.downcase : value
      @@true_values.include?(val) || (value.is_a?(String) && (I18n.t('all.value._true') == val || I18n.t('all.value._yes') == val))
    end
  end
end
