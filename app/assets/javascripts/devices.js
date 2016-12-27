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
function devices_observe_planning(context) {

  $.each($('.last-sent-at', context), function(i, element) {
    if ($(element).find('span').html() == '') $(element).hide();
  });

  function set_last_sent_at(route) {
    var container = $("[data-route_id='" + route.id + "'] .last-sent-at", context);
    route.i18n = mustache_i18n;
    container.html(SMT['routes/last_sent_at'](route));
    route.last_sent_at ? container.show() : container.hide();
  }

  function set_planning_routes_last_sent_at(routes) {
    $.each(routes, function(i, route) {
      set_last_sent_at(route);
    });
  }

  function clear_last_sent_at(route) {
    $("[data-route_id='" + route.id + "'] .last-sent-at", context).hide();
  }

  function clear_planning_routes_last_sent_at(routes) {
    $.each(routes, function(i, route) {
      clear_last_sent_at(route);
    });
  }

  var modalTitles = {
    tomtom: "TomTom WEBFLEET"
  };

  $(context).off('click', '.device-operation').on('click', '.device-operation', function(e) {

    if (!confirm(I18n.t('all.verb.confirm'))) {
      return;
    }

    var from = $(e.target),
      service = from.data('service'),
      operation = from.data('operation'),
      url = '/api/0.1/devices/' + service + '/' + operation,
      data = {};

    var dialog = bootstrap_dialog({
      icon: 'fa-bars',
      title: service && (modalTitles[service] || (service.substr(0, 1).toUpperCase() + service.substr(1))),
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
            set_planning_routes_last_sent_at(data);
          else if (from.data('planning-id') && operation == 'clear')
            clear_planning_routes_last_sent_at(data);
          else if (from.data('route-id') && operation == 'send')
            set_last_sent_at(data);
          else if (from.data('route-id') && operation == 'clear')
            clear_last_sent_at(data);

          if (service == 'tomtom') update_stop_status = true; // for backgroundTask
        }
      },
      complete: function() {
        dialog.modal('hide');
      },
      error: function() {
        stickyError(I18n.t('plannings.edit.' + service + '_' + operation + (from.data('type') ? '_' + from.data('type') : '') + '.fail'));
      }
    });

    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

}

function devices_observe_vehicle(params) {

  function devices_init_vehicle(base_name, name) {
    $.ajax({
      url: '/api/0.1/devices/' + name + '/devices.json',
      data: {
        customer_id: params.customer_id
      },
      dataType: 'json',
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          data.unshift(' '); // Blank option
        }
        $('#' + base_name + '_' + name + '_id').select2({
          data: data,
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
        $('#' + base_name + '_' + name + '_id').val(params[name + '_id']).trigger('change');
      }
    });
  }

  /* API: Devices */
  $.each(['tomtom', 'teksat', 'orange'], function(i, name) {
    if (params[name]) devices_init_vehicle('vehicle_usage_vehicle', name);
  });
}

function devices_observe_customer(params) {

  function devices_init_customer(base_name, config, params) {
    var requests = [];

    function clear_callback() {
      $('#' + config.name + '_success').addClass('hidden');
      $('#' + config.name + '_not_found').addClass('hidden');
      $('.' + config.name + '-api-sync').attr('disabled', 'disabled');
    }

    function success_callback() {
      $('#' + config.name + '_success').removeClass('hidden');
      $('#' + config.name + '_not_found').addClass('hidden');
      $('.' + config.name + '-api-sync').removeAttr('disabled');
    }

    function error_callback() {
      $('#' + config.name + '_success').addClass('hidden');
      $('#' + config.name + '_not_found').removeClass('hidden');
      $('.' + config.name + '-api-sync').attr('disabled', 'disabled');
    }

    function user_credentials() {
      var hash = {};

      // Optional Customer ID
      if (params.customer_id) hash.customer_id = params.customer_id;

      // Customer ID and Username
      $.each(config.inputs, function(i, name) {
        hash[config.name + '_' + name] = $('#' + base_name + '_' + config.name + '_' + name).val();
      });

      // Prevent submitting default password value
      $.each(config.password_inputs, function(i, name) {
        var passwd = $('#' + base_name + '_' + config.name + '_' + name).val();
        if (passwd != params.default_password) hash[config.name + '_' + name] = passwd;
      });

      return hash;
    }

    // Check TomTom Credentials Without Before / Complete Callbacks
    function check_credentials() {
      requests.push($.ajax({
        url: '/api/0.1/devices/' + config.name + '/auth.json',
        data: user_credentials(),
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          if (data && data.error) {
            error_callback();
            stickyError(data.error);
          } else {
            success_callback();
          }
        }
      }));
    }

    // Check Credentials: Observe User Events with Delay
    function observe() {

      var timeout_id;

      function all_fields_filled() {
        var array = [];

        var count = Object.keys(config.inputs).length;
        if (config.password_inputs) count += Object.keys(config.password_inputs).length;

        $.each(config.inputs, function(i, name) {
          if ($('#' + base_name + '_' + config.name + '_' + name).val() != '') array.push(name)
        });

        if (config.password_inputs) {
          $.each(config.password_inputs, function(i, name) {
            if ($('#' + base_name + '_' + config.name + '_' + name).val() != '') array.push(name)
          });
        }
        return array.length == count;
      }

      function check_credentials_with_callbacks() {

        // Don't check credentials unless all fields are filled
        if (!all_fields_filled()) {
          clear_callback();
          return;
        }

        // Send request
        requests.push($.ajax({
          url: '/api/0.1/devices/' + config.name + '/auth.json',
          data: $.extend(user_credentials(), {
            check_only: 1
          }),
          dataType: 'json',
          beforeSend: function(jqXHR, settings) {
            hideNotices();
            $.each(requests, function(i, request) {
              request.abort();
            });
            beforeSendWaiting();
          },
          complete: function(jqXHR, textStatus) {
            completeWaiting();
          },
          success: function(data, textStatus, jqXHR) {
            if (data && data.error) {
              error(data.error);
              error_callback();
            } else {
              success_callback();
            }
          }
        }));
      }

      function check_credentials_with_delay() {
        if (timeout_id) clearTimeout(timeout_id);
        timeout_id = setTimeout(check_credentials_with_callbacks, 750);
      }

      // Observe Inputs
      $.each([].concat(config.inputs, config.password_inputs), function(i, name) {
        $('#' + base_name + '_' + config.name + '_' + name).keyup(function(e) {
          check_credentials_with_delay();
        });
      });

      // Sync
      $('.' + config.name + '-api-sync').click(function(e) {
        if (confirm(I18n.t('customers.form.sync.' + config.name + '.confirm'))) {
          $.ajax({
            url: '/api/0.1/devices/' + config.name + '/sync.json',
            type: 'POST',
            data: $.extend(user_credentials(), {
              customer_id: params.customer_id
            }),
            beforeSend: function(jqXHR, settings) {
              beforeSendWaiting();
            },
            complete: function(jqXHR, textStatus) {
              completeWaiting();
            },
            success: function(data, textStatus, jqXHR) {
              alert(I18n.t('customers.form.sync.complete'));
            }
          });
        }
      });
    }

    // Expand or Collapse Widget
    function toggle_panel() {
      $('#' + config.name + '_container .panel-collapse').collapse('toggle');
    }

    // Admin: Toggle Container When Toggling Check-Box
    function toggle_widget() {
      function toggle(enabled) {
        enabled ? $('#' + config.name + '_container').show() : $('#' + config.name + '_container').hide()
      }
      $('#' + base_name + '_enable_' + config.name).change(function(e) {
        toggle($(e.target).is(':checked'))
      });
      $('#' + base_name + '_enable_' + config.name).trigger('change');
      toggle_panel();
    }

    /* Password Inputs: Set value */
    $.each(config.password_inputs, function(i, name) {
      var password_field = $('#' + [base_name, config.name, name].join('_'));
      if (params[config.name] && $(password_field).val() == '') $(password_field).val(params.default_password);
    });

    // Check TomTom on Page Load if Customer has Service Enabled with Credentials
    if (params[config.name]) {
      toggle_panel();
      check_credentials();
    }

    // Observe Widget if Customer has Service Enabled or Admin (New Customer)
    if (params['enable_' + config.name] || params.admin) observe();

    // Toggle Widget if Customer has Service Enabled with Credentials or Admin (New Customer)
    if (params[config.name] || params.admin) toggle_widget();
  }

  function observe_form() {
    /* Chrome / FF, Prevent Sending Default Password
       The browsers would ask to remember it. */
    $('form.clear-passwords').submit(function(e) {
      $.each($(e.target).find('input[type=\'password\']'), function(i, element) {
        if ($(element).val() == params.default_password) $(element).val('');
      });
      return true;
    });
  }

  observe_form();

  $.each([{
    name: 'tomtom',
    inputs: ['account', 'user'],
    password_inputs: ['password']
  }, {
    name: 'teksat',
    inputs: ['url', 'customer_id', 'username'],
    password_inputs: ['password']
  }, {
    name: 'orange',
    inputs: ['user'],
    password_inputs: ['password']
  }, {
    name: 'masternaut',
    inputs: ['user'],
    password_inputs: ['password']
  }, {
    name: 'alyacom',
    inputs: ['association', 'api_key']
  }], function(i, config) {
    if (params['enable_' + config.name]) {
      devices_init_customer('customer', config, params);
    }
  });
}
