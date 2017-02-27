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

var customers_index = function (params) {

  var map_layers = params.map_layers,
    map_attribution = params.map_attribution;

  var is_map_init = false;

  var map_init = function () {

    var map = mapInitialize(params);
    L.control.attribution({
      prefix: false
    }).addTo(map);

    var layer = L.featureGroup();
    map.addLayer(layer);


    function determineIconColor(customer) {

      var color = {
        isActiv: '558800', // green
        isNotActiv: '707070', // grey
        isTest: '0077A3' // blue
      };

      return customer.test ? color.isTest : (customer.isActiv ? color.isActiv : color.isNotActiv);

    }

    var display_customers = function (data) {

      $.each(data.customers, function (i, customer) {

        var iconImg = '/images/point-' + determineIconColor(customer) + '.svg';

        var marker = L.marker(new L.LatLng(customer.lat, customer.lng), {

          icon: new L.NumberedDivIcon({
            number: customer.max_vehicles,
            iconUrl: iconImg,
            iconSize: new L.Point(12, 12),
            iconAnchor: new L.Point(6, 6),
            popupAnchor: new L.Point(0, -6),
            className: "small"
          })

        }).addTo(layer).bindPopup(customer.name);

      });

      map.invalidateSize();

      if (layer.getLayers().length > 0) {
        map.fitBounds(layer.getBounds(), {
          maxZoom: 15,
          padding: [20, 20]
        });
      }

    };

    $.ajax({
      url: '/customers.json',
      beforeSend: beforeSendWaiting,
      success: display_customers,
      complete: completeWaiting,
      error: ajaxError
    });

  };

  $('#accordion').on('show.bs.collapse', function (event, ui) {
    if (!is_map_init) {
      is_map_init = true;
      map_init();
    }
  });
};

var customers_edit = function (params) {
  /* Speed Multiplier */
  $('form.number-to-percentage').submit(function (e) {
    $.each($(e.target).find('input[type=\'number\'].number-to-percentage'), function (i, element) {
      var value = $(element).val() ? Number($(element).val()) / 100 : 1;
      $($(document.createElement('input')).attr('type', 'hidden').attr('name', 'customer[' + $(element).attr('name') + ']').val(value)).insertAfter($(element));
    });
    return true;
  });

  /* API: Devices */
  devices_observe_customer($.extend(params, {
    default_password: Math.random().toString(36).slice(-8)
  }));

  $('#customer_end_subscription').datepicker({
    autoclose: true,
    calendarWeeks: true,
    todayHighlight: true,
    format: I18n.t("all.datepicker"),
    language: I18n.currentLocale(),
    zIndexOffset: 1000
  });

  $('#customer_take_over').timeEntry({
    show24Hours: true,
    showSeconds: true,
    initialField: 1,
    defaultTime: '00:00:00',
    spinnerImage: ''
  });

  $('#customer_print_header').wysihtml5({
    locale: I18n.currentLocale() == 'fr' ? 'fr-FR' : 'en-US',
    toolbar: {
      link: false,
      image: false,
      blockquote: false,
      size: 'sm',
      fa: true
    }
  });

  $(document).on('change', '#customer_router', function () {
    var routerId = this.value.split('_')[0];
    var routerOptions = params.routers_options[routerId];

    if (routerId && routerOptions) {
      if (routerOptions.motorway === 'true') {
        $('#customer_router_options_motorway_input').fadeIn();
      } else {
        $('#customer_router_options_motorway_input').fadeOut();
      }

      if (routerOptions.toll === 'true') {
        $('#customer_router_options_toll_input').fadeIn();
      } else {
        $('#customer_router_options_toll_input').fadeOut();
      }

      if (routerOptions.trailers === 'true') {
        $('#customer_router_options_trailers_input').fadeIn();
      } else {
        $('#customer_router_options_trailers_input').fadeOut();
      }

      if (routerOptions.weight === 'true') {
        $('#customer_router_options_weight_input').fadeIn();
      } else {
        $('#customer_router_options_weight_input').fadeOut();
      }

      if (routerOptions.weight_per_axle === 'true') {
        $('#customer_router_options_weight_per_axle_input').fadeIn();
      } else {
        $('#customer_router_options_weight_per_axle_input').fadeOut();
      }

      if (routerOptions.height === 'true') {
        $('#customer_router_options_height_input').fadeIn();
      } else {
        $('#customer_router_options_height_input').fadeOut();
      }

      if (routerOptions.width === 'true') {
        $('#customer_router_options_width_input').fadeIn();
      } else {
        $('#customer_router_options_width_input').fadeOut();
      }

      if (routerOptions.length === 'true') {
        $('#customer_router_options_length_input').fadeIn();
      } else {
        $('#customer_router_options_length_input').fadeOut();
      }
    }
  });

  $('form').submit(function () {
    if ($('#customer_router_options_length_input').is(':hidden')) {
      $('#customer_router_options_length').val('');
    }
    if ($('#customer_router_options_width_input').is(':hidden')) {
      $('#customer_router_options_width').val('');
    }
    if ($('#customer_router_options_height_input').is(':hidden')) {
      $('#customer_router_options_height').val('');
    }
    if ($('#customer_router_options_weight_per_axle_input').is(':hidden')) {
      $('#customer_router_options_weight_per_axle').val('');
    }
    if ($('#customer_router_options_weight_input').is(':hidden')) {
      $('#customer_router_options_weight').val('');
    }
    if ($('#customer_router_options_trailers_input').is(':hidden')) {
      $('#customer_router_options_trailers').val('');
    }
    if ($('#customer_router_options_toll_input').is(':hidden')) {
      $('#customer_router_options_toll_yes').prop('checked', true);
      $('#customer_router_options_toll_no').prop('checked', false);
    }
    if ($('#customer_router_options_motorway_input').is(':hidden')) {
      $('#customer_router_options_motorway_yes').prop('checked', true);
      $('#customer_router_options_motorway_no').prop('checked', false);
    }

    return true;
  });
};

Paloma.controller('Customers', {
  index: function () {
    customers_index(this.params);
  },
  new: function () {
    customers_edit(this.params);
  },
  create: function () {
    customers_edit(this.params);
  },
  edit: function () {
    customers_edit(this.params);
  },
  update: function () {
    customers_edit(this.params);
  }
});
