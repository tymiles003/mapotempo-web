# Copyright © Mapotempo, 2013-2014
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
module ApplicationHelper
  def span_tag(content)
    content_tag :span, content, class: 'default-color'
  end

  def number_to_human(number, options = {})
    options.merge! delimiter: I18n.t('number.format.delimiter'), separator: I18n.t('number.format.separator'), strip_insignificant_zeros: true
    super number, options
  end

  def customised_color_verification(data)
    if data.nil?
      DEFAULT_COLOR
    elsif COLORS_TABLE.include? data
      DEFAULT_COLOR
    else
      data
    end
  end

  def locale_distance(distance, unit = 'kms', options = {})
    base_options = { units: :distance, precision: 3, format: '%n %u' }
    options.merge!(base_options)

    if unit != 'kms'
      distance = distance / 1.609344
      options[:units] = :distance_miles
    end

    if !options[:display_unit].nil? && !options[:display_unit]
      options.except!(:units)
    end

    number_to_human(distance, options)
  end
end