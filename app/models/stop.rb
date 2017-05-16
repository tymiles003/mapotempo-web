# Copyright © Mapotempo, 2013-2017
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
class Stop < ApplicationRecord
  default_scope { order(:index) }

  belongs_to :route
  belongs_to :visit

  nilify_blanks

  include TimeAttr
  attribute :time, ScheduleType.new
  time_attr :time

  validates :route, presence: true

  before_save :out_of_date

  scope :for_customer, ->(customer) { joins(Route).where(route: {planning_id: customer.planning_ids}) }

  amoeba do
    enable
  end

  # Return best fit time window, and late (positive) time or waiting time (negative).
  def best_open_close(time)
    [[open1, close1], [open2, close2]].select{ |open, close|
      open || close
    }.collect{ |open, close|
      [open, close, eval_open_close(open, close, time)]
    }.min_by{ |_open, _close, eval|
      eval.abs
    }
  end

  private

  def eval_open_close(open, close, time)
    if open && time < open
      time - open # Negative
    elsif close && time > close
      soft_upper_bound = self.route.planning.customer.optimization_stop_soft_upper_bound || Mapotempo::Application.config.optimize_stop_soft_upper_bound
      if soft_upper_bound > 0
        (time - close) * soft_upper_bound # Positive
      else
        2**31 # Strict
      end
    else
      0
    end
  end

  def out_of_date
    if active_changed?
      route.out_of_date = true
      route.optimized_at = route.last_sent_to = route.last_sent_at = nil
    end
  end
end
