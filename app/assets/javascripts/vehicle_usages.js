// Copyright © Mapotempo, 2013-2017
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
'use strict';

var vehicle_usages_form = function(params) {
  'use strict';

  /* Speed Multiplier */
  $('form.number-to-percentage').submit(function(e) {
    $.each($(e.target).find('input[type=\'number\'].number-to-percentage'), function(i, element) {
      var value = $(element).val() ? Number($(element).val()) / 100 : null;
      $($(document.createElement('input')).attr('type', 'hidden').attr('name', 'vehicle_usage[vehicle][' + $(element).attr('name') + ']').val(value)).insertAfter($(element));
    });
    return true;
  });

  $('#vehicle_usage_open, #vehicle_usage_close, #vehicle_usage_rest_start, #vehicle_usage_rest_stop, #vehicle_usage_rest_duration, #vehicle_usage_service_time_start, #vehicle_usage_service_time_end').timeEntry({
    show24Hours: true,
    spinnerImage: '',
    defaultTime: '00:00'
  });

  $('#vehicle_usage_vehicle_color').simplecolorpicker({
    theme: 'fontawesome'
  });

  customColorInitialize('#vehicle_usage_vehicle_color');

  $('#capacity-unit-add').click(function(event) {
    $(this).hide();
    $('#vehicle_usage_vehicle_capacity_input .input-group').show();
    event.preventDefault();
    return false;
  });

  /* API: Devices */
  devicesObserveVehicle.init(params);

  routerOptionsSelect('#vehicle_usage_vehicle_router', params);
};

Paloma.controller('VehicleUsages', {
  new: function() {
    vehicle_usages_form(this.params);
  },
  create: function() {
    vehicle_usages_form(this.params);
  },
  edit: function() {
    vehicle_usages_form(this.params);
  },
  update: function() {
    vehicle_usages_form(this.params);
  },
  toggle: function() {
    vehicle_usages_form(this.params);
  }
});
