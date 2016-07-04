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
class Stop < ActiveRecord::Base
  belongs_to :route
  belongs_to :visit

  nilify_blanks
  validates :route, presence: true

  before_save :out_of_date

  amoeba do
    enable
  end

  # Return best fit time window, and late (positive) time or waiting time (negative).
  def best_open_close(time)
    [[open1, close1], [open2, close2]].select{ |open, close|
      open || close
    }.collect{ |open, close|
      [open, close, eval_open_close(open, close, time)]
    }.select{ |open, close, eval|
      !eval.nil?
    }.min_by{ |open, close, eval|
      eval.abs
    }
  end

  private

  def eval_open_close(open, close, time)
    if open && time < open
      time - open # Negative
    elsif close && time > close
      (time - close) * (self.route.planning.customer.optimization_soft_upper_bound || 1)  # Positive
    else
      0
    end
  end

  def out_of_date
    if active_changed?
      route.out_of_date = true
      route.optimized_at = nil
    end
  end
end
