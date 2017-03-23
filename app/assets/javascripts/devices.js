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

function devices_observe_planning(context, callback) {

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

          callback && callback(from); // for backgroundTask
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
          // placeholder: I18n.t('vehicle_usages.form.devices.placeholder'),
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
    if (params[name]) devices_init_vehicle('vehicle_usage_vehicle_devices', name);
  });
}

function devices_observe_customer(params) {
  function devices_init_customer(base_name, config, params) {
    var requests = [];

    function clear_callback() {
      $('.' + config.name + '-api-sync').attr('disabled', 'disabled');
      $('#' + config.name + '_container').removeClass('panel-success panel-danger').addClass('panel-default');
    }

    function success_callback() {
      $('.' + config.name + '-api-sync').removeAttr('disabled');
      $('#' + config.name + '_container').removeClass('panel-default panel-danger').addClass('panel-success');
    }

    function error_callback(apiError) {
      apiError = apiError || false;
      var apiClass = apiError ? 'api-error' : '';
      $('.' + config.name + '-api-sync').attr('disabled', 'disabled');
      $('#' + config.name + '_container').removeClass('panel-default panel-success').addClass('panel-danger');
    }

    function user_credentials() {
      var hash = {};
      var device = config.name;

      // Optional Customer ID
      if (params.customer_id) {
        hash.customer_id = params.customer_id;
      }

      // Customer ID and Username
      $.each(config, function(key, value) {
        if($.inArray(key, ['password', 'enable', 'name']) == -1) {
          hash[device + '_' + key] = $('#' + base_name + '_' + device + '_' + key).val();
        }
      });

      // Prevent submitting default password value
      var passwd = $('#' + base_name + '_' + device + '_password').val();
      if (passwd != params.default_password) {
        hash[device + '_password'] = passwd;
      }

      return hash;
    }

    // Check Credentials Without Before / Complete Callbacks
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
        },
        error: function(jqXHR, textStatus, error) {
          error_callback(true);
        } 
      }));
    }

    // Check Credentials: Observe User Events with Delay
    function observe() {
      var timeout_id;

      function all_fields_filled() {
        var isValid = true;
        var search = $('input[type="text"], input[type="password"]', "#" + config.name);

        search.each(function() {
          var id = $(this).attr('id');

          if (typeof id !== typeof undefined && id !== false) {
            if ($(this).val() == "") {
              isValid = false;
            }
          }
        });
        return isValid;
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
          },
          error: function(jqXHR, textStatus, error) {
            error_callback(true);
          } 
        }));
      }

      function check_credentials_with_delay() {
        if (timeout_id) clearTimeout(timeout_id);
        timeout_id = setTimeout(check_credentials_with_callbacks, 750);
      }

      // Listen all inputs on KeyUp event
      $('#devices_settings input').on('keyup', function(e) {
        check_credentials_with_delay();
      });

      // Sync
      $('.' + config.name + '-api-sync').on('click', function(e) {
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

    /* Password Inputs: set fake password  (input view fake) */
    if("password" in config) {
      var password_field = '#' + [base_name, config.name, "password"].join('_');
      if ($(password_field).val() == '') {
        $(password_field).val(params.default_password);
      }
    };

    // Check credantial for current device config
    // Observe Widget if Customer has Service Enabled or Admin (New Customer)
    check_credentials();
    observe();
  }

  function observe_form() {
    /* Chrome / FF, Prevent Sending Default Password
       The browsers would ask to remember it. */
    $('form.clear-passwords').on('submit', function(e) {
      $.each($(e.target).find('input[type=\'password\']'), function(i, element) {
        if ($(element).val() == params.default_password) {
          $(element).val('');
        }
      });
      return true;
    });
  }

  observe_form();

  $.each(params['devices'], function(deviceName, config) {
    config.name = deviceName;
    devices_init_customer('customer_devices', config, params);
  });
}
