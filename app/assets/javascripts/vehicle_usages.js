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

var vehicle_usages_form = function(params) {
  $('#vehicle_usage_open, #vehicle_usage_close, #vehicle_usage_rest_start, #vehicle_usage_rest_stop, #vehicle_usage_rest_duration, #vehicle_usage_service_time_start, #vehicle_usage_service_time_end').timeEntry({
    show24Hours: true,
    spinnerImage: ''
  });

  $('#vehicle_usage_vehicle_color').simplecolorpicker({
    theme: 'fontawesome'
  });

  function observeTomTom(params) {
    $.ajax({
      url: '/api/0.1/customers/' + params.customer_id + '/tomtom_ids',
      dataType: 'json',
      error: ajaxError,
      success: function(data, textStatus, jqXHR) {

        data[''] = ' ';

        $('#vehicle_usage_vehicle_tomtom_id').select2({
          data: $.map(data, function(name, id) {
            return { id: id, text: name }
          }),
          theme: 'bootstrap',
          width: '100%',
          minimumResultsForSearch: -1,
          templateResult: function(data_selection) {
            return data_selection.text;
          },
          templateSelection: function(data_selection) {
            return data_selection.text;
          }
        });

        $('#vehicle_usage_vehicle_tomtom_id').val(params.tomtom_id).trigger('change');
      }
    });
  }

  if (params.tomtom) observeTomTom(params);

}

Paloma.controller('VehicleUsage').prototype.new = function() {
  vehicle_usages_form(this.params);
};

Paloma.controller('VehicleUsage').prototype.create = function() {
  vehicle_usages_form(this.params);
};

Paloma.controller('VehicleUsage').prototype.edit = function() {
  vehicle_usages_form(this.params);
};

Paloma.controller('VehicleUsage').prototype.update = function() {
  vehicle_usages_form(this.params);
};
