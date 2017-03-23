// Copyright © Mapotempo, 2016-2017
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
var devicesObservePlanning = (function() {

  var _context;

  var _setLastSentAt = function(route) {
    var container = $("[data-route_id='" + route.id + "'] .last-sent-at", _context);
    route.i18n = mustache_i18n;
    container.html(SMT['routes/last_sent_at'](route));
    route.last_sent_at ? container.show() : container.hide();
  }

  var _setPlanningRoutesLastSentAt = function(routes) {
    $.each(routes, function(i, route) {
      _setLastSentAt(route);
    });
  }

  var _clearLastSentAt = function(route) {
    $("[data-route_id='" + route.id + "'] .last-sent-at", _context).hide();
  }

  var _clearPlanningRoutesLastSentAt = function(routes) {
    $.each(routes, function(i, route) {
      _clearLastSentAt(route);
    });
  }

  var _devicesInitVehicle = function(callback) {

    $.each($('.last-sent-at', _context), function(i, element) {
      if ($(element).find('span').html() == '') $(element).hide();
    });

    // Still needed, maybe ask to FLO why ?!
    $(_context).off('click', '.device-operation').on('click', '.device-operation', function(e) {
      if (!confirm(I18n.t('all.verb.confirm'))) return;

      var from = $(e.target),
        service = from.data('service'),
        operation = from.data('operation'),
        url = '/api/0.1/devices/' + service + '/' + operation,
        data = {};

      var dialog = bootstrap_dialog({
        icon: 'fa-bars',
        title: service && service.substr(0, 1).toUpperCase() + service.substr(1),
        message: SMT['modals/default_with_progress']({
          msg: I18n.t('plannings.edit.dialog.' + service + '.in_progress')
        })
      });

      if (from.data('planning-id')) data.planning_id = from.data('planning-id');
      if (from.data('route-id')) data.route_id = from.data('route-id');
      if (from.data('type')) data.type = from.data('type');

      $.ajax({
        url: url + (data.planning_id ? '_multiple' : ''),
        type: (operation == 'clear') ? 'DELETE' : 'POST',
        dataType: 'json',
        data: data,
        beforeSend: function() {
          dialog.modal('show');
        },
        success: function(data) {
          if (data && data.error) {
            stickyError(data.error);
          } else {
            notice(I18n.t('plannings.edit.' + service + '_' + operation + (from.data('type') ? '_' + from.data('type') : '') + '.success'));

            if (from.data('planning-id') && operation == 'send')
              _setPlanningRoutesLastSentAt(data);
            else if (from.data('planning-id') && operation == 'clear')
              _clearPlanningRoutesLastSentAt(data);
            else if (from.data('route-id') && operation == 'send')
              _setLastSentAt(data);
            else if (from.data('route-id') && operation == 'clear')
              _clearLastSentAt(data, _context);

            callback && callback(from); // for backgroundTask
          }
        },
        complete: function() {
          dialog.modal('hide');
        },
        error: function() {
          stickyError(I18n.t('plannings.edit.' + service + (from.data('type') ? '_' + from.data('type') : '') + '.fail'));
        }
      });

      // Reset Dropdown
      $(this).closest(".dropdown-menu").prev().dropdown("toggle");
      return false;
    });
  }

  var init = function(context, callback) {
    _context = context;
    _devicesInitVehicle(callback);
  }

  return { init: init };

})();
