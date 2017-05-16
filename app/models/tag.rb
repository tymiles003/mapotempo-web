# Copyright © Mapotempo, 2013-2016
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
class Tag < ApplicationRecord
  ICONS_TABLE = %w(square diamon star user).freeze

  belongs_to :customer
  has_and_belongs_to_many :visits
  has_and_belongs_to_many :plannings

  nilify_blanks
  auto_strip_attributes :label

  include RefSanitizer

  validates :label, presence: true
  validates :ref, uniqueness: { scope: :customer_id, case_sensitive: true }, allow_nil: true, allow_blank: true
  validates_format_of :color, with: /\A(|\#[A-Fa-f0-9]{6})\Z/, allow_nil: true
  validates_inclusion_of :icon, in: [''] + ICONS_TABLE, allow_nil: true

  amoeba do
    exclude_association :visits
    exclude_association :plannings
  end
end
