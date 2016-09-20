// Copyright © Mapotempo, 2016
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
// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var deliverable_units_form = function() {
  var optimisationOverloadMultiplier = function() {
    var input = $('input[name=deliverable_unit\\[optimization_overload_multiplier\\]]');
    if ($('#deliverable_unit_optimization_overload_multiplier_no').prop('checked')) {
      input.css('visibility', 'hidden');
      input.val(input.attr('placeholder') == '0' ? '' : '0');
      input.attr('required', false);
    }
    else {
      input.css('visibility', 'visible');
      if (!input.val()) input.val(input.attr('placeholder') != '0' ? '' : '1');
      if (input.attr('placeholder') == '0') input.attr('required', true);
    }
  }
  optimisationOverloadMultiplier();
  $('input[name="deliverable_unit_optimization_overload_multiplier"]').change(function() {
    optimisationOverloadMultiplier();
  });
};

Paloma.controller('DeliverableUnits', {
  new: function() {
    deliverable_units_form();
  },
  create: function() {
    deliverable_units_form();
  },
  edit: function() {
    deliverable_units_form();
  },
  update: function() {
    deliverable_units_form();
  }
});
