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

  $('[data-toggle="dropdown"]').parent().on('show.bs.dropdown', function(e){
    $(this).find('.dropdown-menu').first().stop(true, true).slideDown({duration: 200});
  });

  $('[data-toggle="dropdown"]').parent().on('hide.bs.dropdown', function(e){
    $(this).find('.dropdown-menu').first().stop(true, true).slideUp({duration: 200});
  });
});

var mapInitialize = function(params) {
  var mapLayer, mapBaseLayers = {}, mapOverlays = {}, nbLayers = 0;
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
    if (layer.overlay)
      mapOverlays[layer_name] = l;
    else
      mapBaseLayers[layer_name] = l;
    nbLayers++;
  };

  var map = L.map('map', {
    attributionControl: false,
    layers: mapLayer
  }).setView([params.map_lat || 0, params.map_lng || 0], 13);
  if (nbLayers > 1)
    L.control.layers(mapBaseLayers, mapOverlays, {position: 'topleft'}).addTo(map);
  else
    map.tileLayer = L.tileLayer(mapLayer.url, {
      maxZoom: 18,
      attribution: mapLayer.attribution
    });

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
}
