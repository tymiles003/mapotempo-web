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
function vehicles_form(params) {
  $('#vehicle_open, #vehicle_close').timeEntry({
    show24Hours: true,
    spinnerImage: ''
  });

  $('#vehicle_color').simplecolorpicker({
    theme: 'fontawesome'
  });

  $('#vehicle_tomtom_id').select2({
    minimumResultsForSearch: -1,
    initSelection: function (element, callback) {
      var data = {
        id: element.val(),
        text: element.val()
      };
      callback(data);
    },
    ajax: {
      url: '/api/0.1/customers/' + params.customer_id + '/tomtom_ids',
      dataType: 'json',
      results: function (data, page) {
        data[''] = ' ';
        return {
          results: $.map(data, function(o, k) {
            return {
              id: k,
              text: o
            };
          })
        };
      },
      cache: true
    },
  });
}

Paloma.controller('Vehicle').prototype.new = function() {
  vehicles_form(this.params);
};

Paloma.controller('Vehicle').prototype.create = function() {
  vehicles_form(this.params);
};

Paloma.controller('Vehicle').prototype.edit = function() {
  vehicles_form(this.params);
};

Paloma.controller('Vehicle').prototype.update = function() {
  vehicles_form(this.params);
};
