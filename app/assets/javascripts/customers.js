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
var customers_index = function(params) {
  var map_layers = params.map_layers,
    map_attribution = params.map_attribution;

  var is_map_init = false;

  var map_init = function() {
    var map = mapInitialize(params);
    L.control.attribution({prefix: false}).addTo(map);

    var layer = L.featureGroup();
    map.addLayer(layer);

    var display_customers = function(data) {
      $.each(data.customers, function(i, customer) {
        var marker = L.marker(new L.LatLng(customer.lat, customer.lng), {
          icon: new L.NumberedDivIcon({
            number: customer.max_vehicles,
            iconUrl: '/images/point-' + (customer.test ? '707070' : '004499') + '.svg',
            iconSize: new L.Point(12, 12),
            iconAnchor: new L.Point(6, 6),
            popupAnchor: new L.Point(0, -6),
            className: "small"
          })
        }).addTo(layer);
      });

      map.invalidateSize();
      if (layer.getLayers().length > 0) {
        map.fitBounds(layer.getBounds().pad(1.1), {
          maxZoom: 15
        });
      }
    }

    $.ajax({
      url: '/customers.json',
      beforeSend: beforeSendWaiting,
      success: display_customers,
      complete: completeWaiting,
      error: ajaxError
    });
  };

  $('#accordion').on('show.bs.collapse', function(event, ui) {
    if (!is_map_init) {
      is_map_init = true;
      map_init();
    }
  });
}

function initTomTom(params) {

  var requests = [];

  function tomTomSuccess() {
    $("#tomtom_success").removeClass('hidden');
    $("#tomtom_not_found").addClass('hidden');
  }

  function tomTomError() {
    $("#tomtom_success").addClass('hidden');
    $("#tomtom_not_found").removeClass('hidden');
  }

  function userTomTomCredentials() {
    var hash = {};

    // Optional Customer ID
    if (params.customer_id) hash.customer_id = params.customer_id;

    // Account and User Name
    var hash = $.extend(hash, {
      account:  $('#customer_tomtom_account').val(),
      user:     $('#customer_tomtom_user').val()
    });

    // Prevent submitting default password value
    var passwd = $('#customer_tomtom_password').val();
    if (passwd != params.tomtom_default_password) hash.password = passwd;

    return hash;
  }

  // Check TomTom Credentials Without Before / Complete Callbacks
  function checkTomTom() {
    requests.push($.ajax({
      url: '/api/0.1/devices/tomtoms/check_credentials',
      data: userTomTomCredentials(),
      dataType: 'json',
      success: function(data, textStatus, jqXHR) {
        if (data.error) {
          tomTomError();
        } else {
          tomTomSuccess();
        }
      }
    }));
  }

  // Check TomTom Credentials: Observe User Events with Delay
  function observeTomTom() {

    var timeoutId;

    function checkTomTomCredentials() {
      requests.push($.ajax({
        url: '/api/0.1/devices/tomtoms/check_credentials',
        data: userTomTomCredentials(),
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
          if (data.error) {
            error(data.error);
            tomTomError();
          } else {
            tomTomSuccess();
          }
        }
      }));
    }

    function checkTomTomCredentialsWithDelay() {
      if (timeoutId) clearTimeout(timeoutId);
      timeoutId = setTimeout(checkTomTomCredentials, 750);
    }

    $('#customer_tomtom_account, #customer_tomtom_user, #customer_tomtom_password').keyup(function(e) {
      checkTomTomCredentialsWithDelay();
    });
  }

  // Expand or Collapse Widget
  function togglePanel() {
    $('#tomtom_container .panel-collapse').collapse('toggle');
  }

  // Admin: Toggle Container When Toggling Check-Box
  function toggleTomTom() {
    function toggleTomTom(enabled) { enabled ? $('#tomtom_container').show() : $('#tomtom_container').hide() }
    $('#customer_enable_tomtom').change(function(e) { toggleTomTom($(e.target).is(':checked')) });
    $('#customer_enable_tomtom').trigger('change');
    togglePanel();
  }

  // Check TomTom on Page Load if Customer has Service Enabled with Credentials
  if (params.tomtom) {
    togglePanel();
    checkTomTom();
  }

  // Observe Widget if Customer has Service Enabled or Admin (New Customer)
  if (params.enable_tomtom || params.admin) observeTomTom();

  // Toggle Widget if Customer has Service Enabled with Credentials or Admin (New Customer)
  if (params.tomtom || params.admin) toggleTomTom();
}

var customers_edit = function(params) {

  initTomTom(params);

  $('#customer_end_subscription').datepicker({
    language: defaultLocale,
    autoclose: true,
    todayHighlight: true
  });

  $('#customer_take_over').timeEntry({
    show24Hours: true,
    showSeconds: true,
    initialField: 1,
    defaultTime: new Date(0, 0, 0, 0, 0, 0),
    spinnerImage: ''
  });

  $.fn.wysihtml5.locale['fr'] = $.fn.wysihtml5.locale['fr-FR'];
  $('#customer_print_header').wysihtml5({
    toolbar: {
      link: false,
      image: false,
      blockquote: false,
      size: 'sm',
      fa: true
    },
    locale: defaultLocale
  });
}

Paloma.controller('Customer').prototype.index = function() {
  customers_index(this.params);
};

Paloma.controller('Customer').prototype.new = function() {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.create = function() {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.edit = function() {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.update = function() {
  customers_edit(this.params);
};
