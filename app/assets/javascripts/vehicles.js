// Copyright © Mapotempo, 2013-2014
//
// This file is part of Mapotempo.
//
// Mapotempo is free software. You can redistribute it and/or
// modify since you respect the terms of the GNU Affero General
// Public License as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Mapotempo is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Mapotempo. If not, see:
// <http://www.gnu.org/licenses/agpl.html>
//
function vehicles_form() {
  $('#vehicle_open, #vehicle_close').timeEntry({
    show24Hours: true,
    spinnerImage: ''
  });

  $('#vehicle_color').simplecolorpicker({
    theme: 'fontawesome'
  });
}

Paloma.controller('Vehicle').prototype.new = function() {
  vehicles_form();
};

Paloma.controller('Vehicle').prototype.create = function() {
  vehicles_form();
};

Paloma.controller('Vehicle').prototype.edit = function() {
  vehicles_form();
};

Paloma.controller('Vehicle').prototype.update = function() {
  vehicles_form();
};
