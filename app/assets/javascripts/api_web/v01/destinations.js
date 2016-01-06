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
Paloma.controller('ApiWeb/V01/Destination').prototype.edit_position = function() {
  destinations_edit(this.params, 'destinations');
};

Paloma.controller('ApiWeb/V01/Destination').prototype.update_position = function() {
  destinations_edit(this.params, 'destinations');
};

Paloma.controller('ApiWeb/V01/Store').prototype.edit_position = function() {
  destinations_edit(this.params, 'stores');
};

Paloma.controller('ApiWeb/V01/Store').prototype.update_position = function() {
  destinations_edit(this.params, 'stores');
};

var api_web_v01_display_destinations_ = function(api, map, markersLayers, cluster, data) {
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
  }

  var addMarker = function(id, lat, lng, icon, color) {
    var licon;
    if (api == 'stores') {
      licon = L.divIcon({
        html: '<i class="fa ' + (icon || 'fa-home') + ' fa-2x store-icon" style="color: ' + (color || 'black') + ';"></i>',
        iconSize: new L.Point(32, 32),
        iconAnchor: new L.Point(16, 16),
        popupAnchor: new L.Point(0, -12),
        className: 'store-icon-container'
      });
    } else {
      licon = new L.icon({
        iconUrl: '/images/' + (icon || 'point') + (color ? '-' + color.substr(1) : '') + '.svg',
        iconSize: new L.Point(12, 12),
        iconAnchor: new L.Point(6, 6),
        popupAnchor: new L.Point(0, -6),
      })
    }
    var marker = L.marker(new L.LatLng(lat, lng), {
      icon: licon
    }).addTo(markersLayers);
    if(cluster) {
      marker.addTo(cluster);
    }
    return marker;
  }

  if (data.tags) {
    $.each(data.tags, function(i, tag) {
      tags[tag.id] = tag;
    });
  }
  if (data[api]) {
    $.each(data[api], function(i, destination) {
      destination = prepare_display_destination(destination);
      if (api == 'stores') destination.store = true;
      if ($.isNumeric(destination.lat) && $.isNumeric(destination.lng)) {
        addMarker(destination.id, destination.lat, destination.lng, destination.icon, destination.color).bindPopup(SMT['stops/show']({
          stop: destination
        }));
      }
    });
  }
}

var api_web_v01_destinations_index = function(params, api) {
  var progressBar = Turbolinks.enableProgressBar();
  progressBar && progressBar.advanceTo(25);

  var map_lat = params.map_lat,
    map_lng = params.map_lng,
    ids = params.ids,
    display_home = params.display_home,
    method = params.method;

  var map = mapInitialize(params);
  L.control.attribution({prefix: false}).addTo(map);
  L.control.scale({
    imperial: false
  }).addTo(map);

  if (display_home) {
    L.marker([map_lat, map_lng], {
      icon: L.divIcon({
        html: '<i class="fa ' + (store.icon || 'fa-home') + ' fa-2x store-icon" style="color: ' + (store.color || 'black') + ';"></i>',
        iconSize: new L.Point(32, 32),
        iconAnchor: new L.Point(16, 16),
        popupAnchor: new L.Point(0, -12)
      })
    }).addTo(map);
  }

  var markersLayers = L.featureGroup();

  var cluster = new L.MarkerClusterGroup({
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

  var display_destinations = function(data) {
    api_web_v01_display_destinations_(api, map, markersLayers, cluster, data);
    if (markersLayers.getLayers().length > 0) {
      map.fitBounds(markersLayers.getBounds().pad(1.1), {
        maxZoom: 15
      });
    }
  }

  progressBar && progressBar.advanceTo(50);
  var params = (ids) ? {ids: ids.join(',')} : {};
  $.ajax({
    url: '/api-web/0.1/' + api + '.json',
    method: method,
    data: params,
    beforeSend: beforeSendWaiting,
    success: function(data) {
      if ((data.destinations && data.destinations.length) || (data.stores && data.stores.length)) {
        display_destinations(data);
      }
      else {
        bootstrap_alert_danger(I18n.t('api_web.v01.destinations.index.none_destinations'));
      }
      progressBar && progressBar.done();
    },
    complete: completeWaiting,
    error: ajaxError
  });
}

Paloma.controller('ApiWeb/V01/Destination').prototype.index = function() {
  api_web_v01_destinations_index(this.params, 'destinations');
};

Paloma.controller('ApiWeb/V01/Store').prototype.index = function() {
  api_web_v01_destinations_index(this.params, 'stores');
};
