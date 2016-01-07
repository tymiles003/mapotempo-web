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

var customers_edit = function(params) {

  var requests = [];
  var timeoutId;

  function tomtomSuccess() {
    $("#tomtom_success").removeClass('hidden');
    $("#tomtom_not_found").addClass('hidden');
  }

  function tomtomNotFound() {
    $("#tomtom_success").addClass('hidden');
    $("#tomtom_not_found").removeClass('hidden');
  }

  function checkTomTom() {
    requests.push($.ajax({
      url: '/api/0.1/customers/' + params.customer_id + '/tomtom_ids',
      success: function(data, textStatus, jqXHR) {
        tomtomSuccess();
      },
      error: function(jqXHR, textStatus, errorThrown) {
        tomtomNotFound();
      }
    }));
  }

  function checkTomTomCredentials() {

    function userTomTomCredentials() {
      var userInputs = {
        account: $('#customer_tomtom_account').val(),
        user: $('#customer_tomtom_user').val()
      }
      /* Prevent submitting default password value */
      var passwd = $('#customer_tomtom_password').val();
      if (passwd != params.tomtom_default_password) userInputs['password'] = passwd;
      return userInputs;
    }

    requests.push($.ajax({
      url: '/api/0.1/customers/' + params.customer_id + '/check_tomtom_credentials',
      data: userTomTomCredentials(),
      beforeSend: function(jqXHR, settings) {
        hideAlert('.alert', 0);
        $.each(requests, function(i, request) {
          request.abort();
        });
        beforeSendWaiting();
      },
      complete: function(jqXHR, textStatus) {
        completeWaiting();
      },
      error: function(jqXHR, textStatus, errorThrown) {
        ajaxError(jqXHR, textStatus, errorThrown);
        tomtomNotFound();
      },
      success: function(data, textStatus, jqXHR) {
        tomtomSuccess();
      }
    }));
  }

  function checkTomTomCredentialsWithDelay() {
    if (timeoutId) clearTimeout(timeoutId);
    timeoutId = setTimeout(checkTomTomCredentials, 750);
  }

  checkTomTom();

  $('#customer_tomtom_account, #customer_tomtom_user, #customer_tomtom_password').keyup(function(e) {
    checkTomTomCredentialsWithDelay();
  });

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
