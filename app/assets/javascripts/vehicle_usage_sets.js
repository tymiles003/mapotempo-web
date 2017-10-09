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

var vehicle_usage_sets_index = function(params) {
  'use strict';

  // override accordion collapse bootstrap code
  $('a.accordion-toggle').click(function() {
    var id = $(this).attr('href');
    window.location.hash = id;
    $('.accordion-body.collapse.in').each(function(index) {
      var $this = $(this);
      if (id !== '#' + $this.attr('id')) {
        $this.collapse('hide');
      }
    });
  });

  if (window.location.hash) {
    $('.accordion-body.collapse.in').each(function(index) {
      var $this = $(this);
      if (window.location.hash !== '#' + $this.attr('id')) {
        $this.removeClass('in');
      }
    });
    $(".accordion-toggle[href!='" + window.location.hash + "']").addClass('collapsed');
    $(window.location.hash).addClass('in');
    $(".accordion-toggle[href='" + window.location.hash + "']").removeClass('collapsed');
  }
};

var vehicle_usage_sets_edit = function(params) {
  $('#vehicle_usage_set_open, #vehicle_usage_set_close, #vehicle_usage_set_rest_start, #vehicle_usage_set_rest_stop, #vehicle_usage_set_rest_duration, #vehicle_usage_set_service_time_start, #vehicle_usage_set_service_time_end').timeEntry({
    show24Hours: true,
    spinnerImage: '',
    defaultTime: '00:00'
  });
};

var vehicle_usage_sets_import = function(params) {
  'use strict';

  var dialog_upload = bootstrap_dialog({
    title: I18n.t('vehicle_usage_sets.import.dialog.import.title'),
    icon: 'fa-upload',
    message: SMT['modals/default_with_progress']({
      msg: I18n.t('vehicle_usage_sets.import.dialog.import.in_progress')
    })
  });

  $(":file").filestyle({
    buttonName: "btn-primary",
    iconName: "fa fa-folder-open",
    buttonText: I18n.t('web.choose_file')
  });

  $('form#new_import_csv').submit(function () {
    var confirmChecks = [];
    $('#import_csv_replace_vehicles', $(this)).is(':checked') && confirmChecks.push('replace_vehicles');
    if (confirmChecks.length > 0 && !confirm(confirmChecks.map(function (c) {
        var vehicle_usage_set_import_translation = 'vehicle_usage_sets.import.dialog.' + c + '_confirm';
        return I18n.t(vehicle_usage_set_import_translation);
      }).join(" \n"))) {
      return false;
    }

    dialog_upload.modal(modal_options());
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
  },
  import: function() {
    vehicle_usage_sets_import(this.params);
  },
  upload_csv: function() {
    vehicle_usage_sets_import(this.params);
  }
});
