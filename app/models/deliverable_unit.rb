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
class DeliverableUnit < ActiveRecord::Base
  belongs_to :customer

  nilify_blanks
  auto_strip_attributes :label
  validates :default_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :default_capacity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :optimization_overload_multiplier, numericality: { greater_than_or_equal_to: -1 }, allow_nil: true

  before_save :out_of_date

  include LocalizedAttr

  attr_localized :default_quantity, :default_capacity, :optimization_overload_multiplier

  def default_optimization_overload_multiplier
    optimization_overload_multiplier || Mapotempo::Application.config.optimize_overload_multiplier
  end

  private

  def out_of_date
    if default_quantity_changed? || default_capacity_changed?
      customer.deliverable_units_updated = true
    end
  end
end
