 /*
 Copyright © Mapotempo, 2016

 This file is part of Mapotempo.

 Mapotempo is free software. You can redistribute it and/or
 modify since you respect the terms of the GNU Affero General
 Public License as published by the Free Software Foundation,
 either version 3 of the License, or (at your option) any later version.

 Mapotempo is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.

 You should have received a copy of the GNU Affero General Public License
 along with Mapotempo. If not, see:
 <http://www.gnu.org/licenses/agpl.html>
*/

function devices_observe_planning(context) {

  $.each($('.last-sent-at', context), function(i, element) {
    if ($(element).find('span').html() == '') $(element).hide();
  });

  function set_last_sent_at(route) {
    var container = $(".last-sent-at[data-route-id='" + route.id + "']", context);
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
    $(".last-sent-at[data-route-id='" + route.id + "']", context).hide();
  }

  function clear_planning_routes_last_sent_at(routes) {
    $.each(routes, function(i, route) {
      clear_last_sent_at(route);
    });
  }

  // API Orange Fleet: Send Planning Routes
  $('.planning-orange-send', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-orange').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.orange_send.success'));
          set_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-orange').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.orange_send.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API Orange Fleet: Clear Planning Routes
  $('.planning-orange-clear', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'DELETE',
      dataType: 'json',
      data: {
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-orange').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.orange_clear.success'));
          clear_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-orange').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.orange_clear.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API Orange Fleet: Send Route
  $('.orange-send', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-orange').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.orange_send.success'));
          set_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-orange').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.orange_send.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API Orange Fleet: Clear Route
  $('.orange-clear', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'DELETE',
      dataType: 'json',
      data: {
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-orange').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.orange_clear.success'));
          clear_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-orange').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.orange_clear.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API Teksat: Send Planning Routes
  $('.planning-teksat-send', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-teksat').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.teksat_send.success'));
          set_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-teksat').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.teksat_send.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API Teksat: Clear Planning Routes
  $('.planning-teksat-clear', context).click(function(e) {
    e.preventDefault();
    $.ajax({
      url: $(e.target).data('url'),
      type: 'DELETE',
      dataType: 'json',
      data: {
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-teksat').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.teksat_clear.success'));
          clear_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-teksat').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.teksat_clear.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API Teksat: Send Route
  $('.teksat-send', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-teksat').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.teksat_send.success'));
          set_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-teksat').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.teksat_send.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API Teksat: Clear Route
  $('.teksat-clear', context).click(function(e) {
    e.preventDefault();
    $.ajax({
      url: $(e.target).data('url'),
      type: 'DELETE',
      dataType: 'json',
      data: {
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-teksat').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.teksat_clear.success'));
          clear_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-teksat').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.teksat_clear.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API TomTom: Send Planning Routes As Waypoints
  $('.planning-tomtom-send-waypoints', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        type: 'waypoints',
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-tomtom').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.tomtom_send_waypoints.success'));
          set_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-tomtom').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.tomtom_send_waypoints.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API TomTom: Send Planning Routes As Orders
  $('.planning-tomtom-send-orders', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        type: 'orders',
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-tomtom').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.tomtom_send_orders.success'));
          set_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-tomtom').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.tomtom_send_orders.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API TomTom: Clear Planning Routes
  $('.planning-tomtom-clear', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'DELETE',
      dataType: 'json',
      data: {
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-tomtom').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.tomtom_clear.success'));
          clear_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-tomtom').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.tomtom_clear.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API TomTom: Send Route As Waypoints
  $('.tomtom-send-waypoints', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        type: 'waypoints',
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-tomtom').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.tomtom_send_waypoints.success'));
          set_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-tomtom').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.tomtom_send_waypoints.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API TomTom: Send Route As Orders
  $('.tomtom-send-orders', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        type: 'orders',
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-tomtom').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.tomtom_send_orders.success'));
          set_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-tomtom').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.tomtom_send_orders.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API TomTom: Clear Route
  $('.tomtom-clear', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'DELETE',
      dataType: 'json',
      data: {
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-tomtom').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.tomtom_clear.success'));
          clear_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-tomtom').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.tomtom_clear.fail'));
      }
    });
    // Reset Dropdown
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    return false;
  });

  // API Masternaut: Send Planning Routes
  $('.planning-masternaut-send', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-masternaut').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.masternaut_send.success'));
          set_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-masternaut').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.masternaut_send.fail'));
      }
    });
    // Reset Dropdown
    $(e.target).closest('.dropdown-menu').dropdown('toggle');
    return false;
  });

  // API Masternaut: Send Route
  $('.masternaut-send', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-masternaut').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.masternaut_send.success'));
          set_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-masternaut').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.masternaut_send.fail'));
      }
    });
    // Reset Dropdown
    $(e.target).closest('.dropdown-menu').dropdown('toggle');
    return false;
  });

  // API Alyacom: Send Planning Routes
  $('.planning-alyacom-send', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        planning_id: $(e.target).data('planning-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-alyacom').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.alyacom_send.success'));
          set_planning_routes_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-alyacom').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.alyacom_send.fail'));
      }
    });
    // Reset Dropdown
    $(e.target).closest('.dropdown-menu').dropdown('toggle');
    return false;
  });

  // API Alyacom: Send Route
  $('.alyacom-send', context).click(function(e) {
    $.ajax({
      url: $(e.target).data('url'),
      type: 'POST',
      dataType: 'json',
      data: {
        route_id: $(e.target).data('route-id')
      },
      beforeSend: function(jqXHR, settings) {
        $('#dialog-alyacom').dialog('open');
      },
      success: function(data, textStatus, jqXHR) {
        if (data && data.error) {
          stickyError(data.error);
        } else {
          notice(I18n.t('plannings.edit.alyacom_send.success'));
          set_last_sent_at(data);
        }
      },
      complete: function(jqXHR, textStatus) {
        $('#dialog-alyacom').dialog('close');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.alyacom_send.fail'));
      }
    });
    // Reset Dropdown
    $(e.target).closest('.dropdown-menu').dropdown('toggle');
    return false;
  });

  // Loading Modals
  $("#dialog-orange").dialog({
    autoOpen: false,
    modal: true
  });

  $("#dialog-teksat").dialog({
    autoOpen: false,
    modal: true
  });

  $("#dialog-tomtom").dialog({
    autoOpen: false,
    modal: true
  });

  $("#dialog-masternaut").dialog({
    autoOpen: false,
    modal: true
  });

  $("#dialog-alyacom").dialog({
    autoOpen: false,
    modal: true
  });
}

function devices_observe_vehicle(params) {

  function devices_init_vehicle(base_name, name) {
    $.ajax({
      url: '/api/0.1/devices/' + name + '/devices',
      data: { customer_id: params.customer_id },
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

    function success_callback() {
      $('#' + config.name + '_success').removeClass('hidden');
      $('#' + config.name + '_not_found').addClass('hidden');
    }

    function error_callback() {
      $('#' + config.name + '_success').addClass('hidden');
      $('#' + config.name + '_not_found').removeClass('hidden');
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
        url: '/api/0.1/devices/' + config.name + '/auth',
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

      function check_credentials_with_callbacks() {
        requests.push($.ajax({
          url: '/api/0.1/devices/' + config.name + '/auth',
          data: $.extend(user_credentials(), { check_only: 1 }),
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
    }

    // Expand or Collapse Widget
    function toggle_panel() {
      $('#' + config.name + '_container .panel-collapse').collapse('toggle');
    }

    // Admin: Toggle Container When Toggling Check-Box
    function toggle_widget() {
      function toggle(enabled) { enabled ? $('#' + config.name + '_container').show() : $('#' + config.name + '_container').hide() }
      $('#' + base_name + '_enable_' + config.name).change(function(e) { toggle($(e.target).is(':checked')) });
      $('#' + base_name + '_enable_' + config.name).trigger('change');
      toggle_panel();
    }

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
    /* Password Inputs: Set value */
    $.each($('form.clear-passwords').find('.clear-default-password'), function(i, element) {
      if ($(element).val() == '') $(element).val(params.default_password);
    });

    /* Chrome / FF, Prevent Sending Default Password
       The browsers would ask to remember it. */
    $('form.clear-passwords').submit(function(e) {
      $.each($(e.target).find('.clear-default-password'), function(i, element) {
        if ($(element).val() == params.default_password) $(element).val('');
      });
      return true;
    });

    $(".api-sync").click(function(e) {
      $.ajax({
        url: $(e.target).data("url"),
        type: "POST",
        data: { customer_id: $(e.target).data("customer-id") },
        beforeSend: function(jqXHR, settings) {
          beforeSendWaiting();
        },
        complete: function(jqXHR, textStatus) {
          completeWaiting();
        },
        success: function(data, textStatus, jqXHR) {
          alert(I18n.t('vehicles.device_sync_complete'));
        }
      });
    });
  }

  observe_form();

  $.each([
    {
      name: 'tomtom',
      inputs: ['account', 'user'],
      password_inputs: ['password']
    },
    {
      name: 'teksat',
      inputs: ['url', 'customer_id', 'username'],
      password_inputs: ['password']
    },
    {
      name: 'orange',
      inputs: ['user'],
      password_inputs: ['password']
    }
  ], function(i, config) {
    if (params['enable_' + config.name]) {
      devices_init_customer('customer', config, params);
    }
  });
}
