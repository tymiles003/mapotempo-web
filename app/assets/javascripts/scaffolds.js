// Copyright © Mapotempo, 2015
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
$(document).on('ready page:load', function() {
  $('.index_toggle_selection').click(function() {
    $('input:checkbox').each(function() {
      this.checked = !this.checked;
    });
  });

  $('[data-toggle="dropdown"]').parent().on('show.bs.dropdown', function(e) {
    $(this).find('.dropdown-menu').first().stop(true, true).slideDown({
      duration: 200
    });
  });

  $('[data-toggle="dropdown"]').parent().on('hide.bs.dropdown', function(e) {
    $(this).find('.dropdown-menu').first().stop(true, true).slideUp({
      duration: 200
    });
  });

  $('.modal').on('shown.bs.modal', function() {
    var modal = this;
    $('input:not(:hidden)', modal).focus();
    $(modal).on('keyup', function(e) {
      if (e.keyCode == 13) {
        $('.btn-primary', modal)[0].click();
      }
    });
  });
  $('.modal').on('hidden.bs.modal', function() {
    var modal = this;
    $(modal).off('keyup');
  });
});

var modal_options = function() {
  return {
    keyboard: false,
    show: true,
    backdrop: 'static'
  };
};

var bootstrap_dialog = function(options) {
  var default_modal = $('#default-modal').clone();
  default_modal.find('.modal-title').html(options.title);
  default_modal.find('.modal-body').html(options.message);
  if (options.icon) {
    default_modal.find('i.fa').addClass(options.icon).show();
  };
  $("body").append(default_modal);
  return default_modal;
};

var mapInitialize = function(params) {
  var mapLayer, mapBaseLayers = {},
    mapOverlays = {},
    nbLayers = 0;
  for (layer_name in params.map_layers) {
    var layer = params.map_layers[layer_name];
    var l = L.tileLayer(layer.url, {
      maxZoom: 18,
      attribution: layer.attribution
    });
    l.name = layer.name;
    if (layer.default) {
      mapLayer = l;
    }
    if (layer.overlay) {
      mapOverlays[layer_name] = l;
    } else {
      mapBaseLayers[layer_name] = l;
    }
    nbLayers++;
  }

  var map = L.map('map', {
    attributionControl: false,
    layers: mapLayer,
    zoomControl: false
  }).setView([params.map_lat || 0, params.map_lng || 0], params.map_zoom || 13);

  L.control.zoom({
    position: 'topleft',
    zoomInText: '+',
    zoomOutText: '-',
    zoomInTitle: I18n.t('plannings.edit.map.zoom_in'),
    zoomOutTitle: I18n.t('plannings.edit.map.zoom_out')
  }).addTo(map);

  if (params.geocoder) {
    var geocoderLayer = L.featureGroup();
    map.addLayer(geocoderLayer);
    var geocoder = L.Control.geocoder({
      geocoder: L.Control.Geocoder.nominatim({
        serviceUrl: "/api/0.1/geocoder/"
      }),
      position: 'topleft',
      placeholder: I18n.t('web.geocoder.search'),
      errorMessage: I18n.t('web.geocoder.empty_result')
    }).addTo(map);
    geocoder.markGeocode = function(result) {
      this._map.fitBounds(result.bbox, {
        maxZoom: 15,
        padding: [20, 20]
      });
      var focusGeocode = L.marker(result.center, {
        icon: new L.divIcon({
          html: '',
          iconSize: new L.Point(14, 14),
          className: 'focus-geocoder'
        })
      }).addTo(geocoderLayer);
      setTimeout(function() {
        geocoderLayer.removeLayer(focusGeocode);
      }, 2000);
    };
  }

  if (params.overlay_layers) {
    $.extend(mapOverlays, params.overlay_layers);
  }

  if (nbLayers > 1) {
    L.control.layers(mapBaseLayers, mapOverlays, {
      position: 'topleft'
    }).addTo(map);
  } else {
    map.tileLayer = L.tileLayer(mapLayer.url, {
      maxZoom: 18,
      attribution: mapLayer.attribution
    });
  }

  map.iconSize = {
    large: {
      name: 'fa-2x',
      size: 32
    },
    medium: {
      name: 'fa-lg',
      size: 20
    },
    small: {
      name: '',
      size: 16
    }
  };

  return map;
};

var customColorInitialize = function(selecter){
  $('#customised_color_picker').click(function(){

      var colorPicker = $('#color_picker'), options_wrap = $(selecter + ' option[selected="selected"]');

      $('.color[data-selected=""]').removeAttr('data-selected');
      $('.color:last-child').attr('data-selected', '');
      options_wrap.removeAttr('selected');

      colorPicker.attr('name', 'store[color]')
      .click()
      .on("input", function() {
          $('.color:last-child').attr('style', 'background-color: ' + this.value)
          .attr('data-color', this.value)
          .attr('title', this.value);
          $(selecter + ' option:last-child').attr('value', this.value)
          .attr('selected', 'selected')
          .val(this.value);
      });
  });
}
