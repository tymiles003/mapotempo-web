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
var api_web_v01_display_destinations_ = function(api, map, data) {
  var tags = {};

  var prepare_display_destination = function(destination) {
    var t = [];
    $.each(tags, function(i, tag) {
      t.push({
        id: tag.id,
        label: tag.label,
        color: tag.color ? tag.color.substr(1) : undefined,
        icon: tag.icon
      });
    });
    destination.tags = t;
    destination.i18n = mustache_i18n;
    return destination;
  };

  var addMarker = function(options) {
    var licon;
    if (options.store) {
      licon = L.divIcon({
        html: '<i class="fa ' + (options.icon ||  'fa-home') + ' ' + map.iconSize[options.icon_size || 'large'].name + ' store-icon" style="color: ' + (options.color || 'black') + ';"></i>',
        iconSize: new L.Point(map.iconSize[options.icon_size || 'large'].size, map.iconSize[options.icon_size || 'large'].size),
        iconAnchor: new L.Point(map.iconSize[options.icon_size || 'large'].size / 2, map.iconSize[options.icon_size || 'large'].size / 2),
        popupAnchor: new L.Point(0, -Math.floor(map.iconSize[options.icon_size || 'large'].size / 2.5)),
        className: 'store-icon-container'
      });
    } else {
      licon = new L.icon({
        iconUrl: '/images/' + (options.icon || 'point') + (options.color ? '-' + options.color.substr(1) : '') + '.svg',
        iconSize: new L.Point(12, 12),
        iconAnchor: new L.Point(6, 6),
        popupAnchor: new L.Point(0, -6),
      });
    }
    var marker = L.marker(new L.LatLng(options.lat, options.lng), {
      icon: licon
    }).addTo((options.store && api == 'destinations') ? map.storesLayers : map.markersLayers);
    if (map.cluster && !options.store) {
      marker.addTo(map.cluster);
    }
    return marker;
  };

  if (data.tags) {
    $.each(data.tags, function(i, tag) {
      tags[tag.id] = tag;
    });
  }
  ['destinations', 'stores'].forEach(function(e) {
    if (data[e]) {
      $.each(data[e], function(i, destination) {
        destination = prepare_display_destination(destination);
        if (e == 'stores') destination.store = true;
        if ($.isNumeric(destination.lat) && $.isNumeric(destination.lng)) {
          addMarker(destination).bindPopup(SMT['stops/show']({
            stop: destination
          }));
        }
      });
    }
  });
};

var api_web_v01_destinations_index = function(params, api) {
  var progressBar = Turbolinks.enableProgressBar();
  progressBar && progressBar.advanceTo(25);

  var map_lat = params.map_lat,
    map_lng = params.map_lng,
    ids = params.ids;

  var map = mapInitialize(params);
  L.control.attribution({
    prefix: false
  }).addTo(map);
  L.control.scale({
    imperial: false
  }).addTo(map);

  var markersLayers = map.markersLayers = L.featureGroup();
  map.addLayer(markersLayers);

  if (api == 'destinations') {
    if (!params.disable_clusters) {
      var cluster = map.cluster = new L.MarkerClusterGroup({
        showCoverageOnHover: false
      });
      map.addLayer(cluster);

      map.on('zoomend', function(e) {
        if (map.getZoom() > 14) {
          map.removeLayer(cluster);
          map.addLayer(markersLayers);
        } else {
          map.removeLayer(markersLayers);
          map.addLayer(cluster);
        }
      });
    }

    var storesLayers = map.storesLayers = L.featureGroup();
    storesLayers.addTo(map);
  }

  var display_destinations = function(data) {
    api_web_v01_display_destinations_(api, map, data);
    if (markersLayers.getLayers().length > 0) {
      map.fitBounds(markersLayers.getBounds(), {
        maxZoom: 15,
        padding: [20, 20]
      });
    }
  }

  progressBar && progressBar.advanceTo(50);
  var ajaxParams = {};
  if (ids) ajaxParams.ids = ids.join(',');
  if (params.store_ids) ajaxParams.store_ids = params.store_ids.join(',');
  $.ajax({
    url: '/api-web/0.1/' + api + '.json',
    method: params.method,
    data: ajaxParams,
    beforeSend: beforeSendWaiting,
    success: function(data) {
      if ((data.destinations && data.destinations.length) || (data.stores && data.stores.length)) {
        display_destinations(data);
      } else {
        stickyError(I18n.t('api_web.v01.destinations.index.none_destinations'));
      }
      progressBar && progressBar.done();
    },
    complete: completeWaiting,
    error: ajaxError
  });
};

Paloma.controller('ApiWeb/V01/Destinations', {
  edit_position: function() {
    destinations_edit(this.params, 'destinations');
  },
  update_position: function() {
    destinations_edit(this.params, 'destinations');
  },
  index: function() {
    api_web_v01_destinations_index(this.params, 'destinations');
  }
});

Paloma.controller('ApiWeb/V01/Stores', {
  edit_position: function() {
    destinations_edit(this.params, 'stores');
  },
  update_position: function() {
    destinations_edit(this.params, 'stores');
  },
  index: function() {
    api_web_v01_destinations_index(this.params, 'stores');
  }
});
