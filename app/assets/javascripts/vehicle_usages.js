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

var devicesObserveVehicle = (function() {
  'use strict';

  const base_name = 'vehicle_usage_vehicle_devices';

  var _buildSelect = function(data, name, devices) {
    $('[data-device=' + name + ']').select2({
      data: data,
      theme: 'bootstrap',
      width: '100%',
      // placeholder: I18n.t('vehicle_usages.form.devices.placeholder'),
      minimumResultsForSearch: -1,
      templateResult: function(data_selection) {
        return data_selection.text;
      },
      templateSelection: function(data_selection) {
        return data_selection.text;
      }
    });
    // this is used to set a default value for select2 builder
    $('[data-device=' + name + ']').val(devices[name + "_id"] || data[0]).trigger("change");
  }

  var _devicesInitVehicle = function(name, params) {
    $.ajax({
      url: '/api/0.1/devices/' + name + '/devices.json',
      data: {
        customer_id: params.customer_id
      },
      dataType: 'json',
      success: function(data, textStatus, jqXHR) {
        // Blank option
        if (data && data.error) stickyError(data.error);
        _buildSelect(data, name, params.devices);
      },
      error: function(jqXHR, textStatus, errorThrown) {
        _buildSelect([errorThrown], name, params.devices);
      }
    });
  }

  var init = function(params) {
    $.each($("[data-device]"), function(i, deviceSelect) {
      _devicesInitVehicle($(deviceSelect).data('device'), params);
    });
  }

  return { init: init };
})();

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
