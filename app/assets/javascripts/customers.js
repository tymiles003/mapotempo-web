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
  'use strict';

  var map_layers = params.map_layers,
    map_attribution = params.map_attribution;

  var is_map_init = false;

  var map_init = function() {

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

    var display_customers = function(data) {

      $.each(data.customers, function(i, customer) {

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

  $('#accordion').on('show.bs.collapse', function(event, ui) {
    if (!is_map_init) {
      is_map_init = true;
      map_init();
    }
  });
};

var customers_edit = function (params) {
  'use strict';

  /* Speed Multiplier */
  $('form.number-to-percentage').submit(function(e) {
    $.each($(e.target).find('input[type=\'number\'].number-to-percentage'), function(i, element) {
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

  routerOptionsSelect('#customer_router', params);

  $(".delete-vehicles").mapotempoDialog({
    bindedCheckboxes: $(".add-vehicle"),
    buttons: [
      {
        text: "Fermer",
        click: function($modal, $e) {
          $e.preventDefault();
          $modal.dismiss();
        }
      }, {
        text: "Supprimer",
        class: "btn-success",
        click: function($modal, $e) {
          console.log('action delete');
          $modal.dismiss();
        }
      }
    ]
  });
};

Paloma.controller('Customers', {
  index: function() {
    customers_index(this.params);
  },
  new: function() {
    customers_edit(this.params);
  },
  create: function() {
    customers_edit(this.params);
  },
  edit: function() {
    customers_edit(this.params);
  },
  update: function() {
    customers_edit(this.params);
  }
});

;(function($) {
  $.utils = {
    // http://stackoverflow.com/a/8809472
    createUUID: function ()
    {
      var d = new Date().getTime();
      if (window.performance && typeof window.performance.now === "function") {
        d += performance.now(); //use high-precision timer if available
      }
      var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        var r = (d + Math.random() * 16) % 16 | 0;
        d = Math.floor(d / 16);
        return (c == 'x' ? r : (r & 0x3 | 0x8)).toString(16);
      });
      return uuid;
    }
  },

  $.fn.dialogue = function (settings) {
    var $modal = $("<div />").attr("id", settings.id).attr("role", "dialog").addClass("modal fade")
          .append($("<div />").addClass("modal-dialog")
            .append($("<div />").addClass("modal-content")
              .append($("<div />").addClass("modal-header")
                .append($("<h4 />").addClass("modal-title").text(settings.title)))
              .append($("<div />").addClass("modal-body")
                .append(settings.content))
              .append($("<div />").addClass("modal-footer")
              )
            )
          );

     if (settings.closeIcon) {
    $modal.find(".modal-header").prepend($("<button />").attr("type", "button").addClass("close").html("&times;")
      .click(function () {
      $modal.dismiss()
      })
    );
    }

    $modal.shown = false;
    $modal.dismiss = function () {
    if (!$modal.shown) {
      window.setTimeout(function () {
        $modal.dismiss();
      }, 50);
      return;
    }
    $modal.modal("hide");
    $modal.prev().remove();
    $modal.empty().remove();
    $("body").removeClass("modal-open");
    }

    // add the buttons
    if( settings.buttons.length > 0 ) {
    var $footer = $modal.find(".modal-footer");
    for(var i=0; i < settings.buttons.length; i++) {
      (function (btn) {
      var button = $("<button />").addClass("btn btn-default")
        .attr("id", btn.id ? btn.id : $.utils.createUUID())
        .attr("type", "button")
        .text(btn.text)
        .on("click", function (event) {
          btn.click($modal, event)
        });

      if( btn.class ) {
        button.addClass(btn.class).removeClass('btn-default');
      }

      $footer.prepend(button);
      })(settings.buttons[i]);
    }
    }

    settings.open($modal);
    $modal.on('shown.bs.modal', function (e) {
      $modal.shown = true;
    });
    $modal.modal("show");
    return $modal;
  },

  $.fn.extend({
    mapotempoDialog: function( options ) {
    this.defaultOptions = {
      bindedCheckboxes: null,
      id: $.utils.createUUID(),
      title: "Suppression des éléments",
      content: "Etes-vous certain de vouloir supprimer ces éléments ?",
      closeIcon: true,
      buttons: [
      { text: "Fermer", id: "close-modal", click: function ($modal) { $modal.dismiss(); } }
      ],
      open: function() {}
    };

    var settings = $.extend({}, this.defaultOptions, options);

    return this.each(function() {
      var $this = $(this);
      if( $this.length > 0) {
        if(settings.bindedCheckboxes != null) {
        var htmlText = $this.html();

        $(document).on('change', settings.bindedCheckboxes, function(e) {
          var nbChecked = settings.bindedCheckboxes.filter(':checked').length;
          (nbChecked > 0) ? $this.html(htmlText + "(<b>"+nbChecked+"</b>)") : $this.html(htmlText);
        });
        }

        $this.on("click", function(e) {
        e.preventDefault();
        $.fn.dialogue(settings);
        });
      }
    });
    }
  });
})(jQuery);
