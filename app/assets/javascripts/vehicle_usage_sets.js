// Copyright © Mapotempo, 2013-2015
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
var vehicle_usage_sets_index = function(params) {
  // override accordion collapse bootstrap code
  $('a.accordion-toggle').click(function() {
    var id = $(this).attr('href');
    window.location.hash = id;
    $('.accordion-body.collapse.in').each(function(index) {
      var $this = $(this);
      if (id != '#' + $this.attr('id')) {
        $this.collapse('hide');
      }
    });
  });

  if (window.location.hash) {
    $('.accordion-body.collapse.in').each(function(index) {
      var $this = $(this);
      if (window.location.hash != '#' + $this.attr('id')) {
        $this.removeClass('in');
      }
    });
    $(window.location.hash).addClass('in');
    $(".accordion-toggle[href!='" + window.location.hash + "']").addClass('collapsed');
  }
};

var vehicle_usage_sets_edit = function(params) {
  $('#vehicle_usage_set_open, #vehicle_usage_set_close, #vehicle_usage_set_rest_start, #vehicle_usage_set_rest_stop, #vehicle_usage_set_rest_duration, #vehicle_usage_set_service_time_start, #vehicle_usage_set_service_time_end').timeEntry({
    show24Hours: true,
    spinnerImage: ''
  });
};

Paloma.controller('VehicleUsageSets', {
  index: function() {
    vehicle_usage_sets_index(this.params);
  },
  new: function() {
    vehicle_usage_sets_edit(this.params);
  },
  create: function() {
    vehicle_usage_sets_edit(this.params);
  },
  edit: function() {
    vehicle_usage_sets_edit(this.params);
  },
  update: function() {
    vehicle_usage_sets_edit(this.params);
  }
});
