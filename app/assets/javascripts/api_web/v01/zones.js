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
var api_web_v01_zones_index = function(params) {
  var progressBar = Turbolinks.enableProgressBar();
  progressBar && progressBar.advanceTo(25);

  var zoning_id = params.zoning_id,
    zone_ids = params.zone_ids,
    vehicles_map = params.vehicles_map,
    destinations = params.destinations,
    destination_ids = params.destination_ids,
    vehicle_usage_set_id = params.vehicle_usage_set_id,
    method = params.method;

  var map = mapInitialize(params);
  L.control.attribution({prefix: false}).addTo(map);
  L.control.scale({
    imperial: false
  }).addTo(map);

  var caption = L.DomUtil.get('zones-caption');
  if (caption) {
    caption.classList.add('leaflet-bar');
    var control_caption = L.Control.extend({
      options: {
          position: 'bottomright'
      },
      onAdd: function (map) {
          var container = caption;
          L.DomEvent.disableClickPropagation(container);
          return container;
      }
    });
    map.addControl(new control_caption());
  }

  var markersLayers = L.featureGroup(),
    stores_marker = L.featureGroup(),
    featureGroup = L.featureGroup();

  map.addLayer(featureGroup).addLayer(stores_marker).addLayer(markersLayers);

  var set_color = function(polygon, vehicle_id) {
    polygon.setStyle({
      color: (vehicle_id ? vehicles_map[vehicle_id].color : '#707070')
    });
  }

  var add_zone = function(zone, geom) {
    var geoJsonLayer;
    if (geom instanceof L.GeoJSON) {
      geoJsonLayer = geom;
      geom = geom.getLayers()[0];
    } else {
      geoJsonLayer = L.geoJson();
      geoJsonLayer.addLayer(geom);
    }
    featureGroup.addLayer(geom);
  }

  var display_zoning = function(data) {
    api_web_v01_display_destinations_('destinations', map, markersLayers, undefined, data);

    stores_marker.clearLayers();
    $.each(data.stores, function(i, store) {
      store.store = true;
      store.i18n = mustache_i18n;
      if ($.isNumeric(store.lat) && $.isNumeric(store.lng)) {
        var m = L.marker(new L.LatLng(store.lat, store.lng), {
          icon: L.divIcon({
            html: '<i class="fa ' + (store.icon || 'fa-home') + ' fa-2x store-icon" style="color: ' + (store.color || 'black') + ';"></i>',
            iconSize: new L.Point(32, 32),
            iconAnchor: new L.Point(16, 16),
            popupAnchor: new L.Point(0, -12),
            className: 'store-icon-container'
          })
        }).addTo(stores_marker).bindPopup(SMT['stops/show']({
          stop: store
        }));
        m.on('mouseover', function(e) {
          m.openPopup();
        }).on('mouseout', function(e) {
          m.closePopup();
        });
      }
    });

    $.each(data.zoning, function(index, zone) {
      var geom = L.geoJson(JSON.parse(zone.polygon));
      set_color(geom, zone.vehicle_id);
      add_zone(zone, geom);
    });

    var bounds = featureGroup.getBounds();
    if (bounds && bounds.isValid()) {
      map.fitBounds(bounds.pad(1.1), {
        maxZoom: 15
      });
    }
  }

  progressBar && progressBar.advanceTo(50);
  var params = {};
  if (zone_ids) params.ids = zone_ids.join(',');
  if (destinations) params.destinations = destinations;
  if (destination_ids) params.destination_ids = destination_ids.join(',');
  if (vehicle_usage_set_id) params.vehicle_usage_set_id = vehicle_usage_set_id;
  $.ajax({
    url: '/api-web/0.1/zonings/' + zoning_id + '/zones.json',
    method: method,
    data: params,
    beforeSend: beforeSendWaiting,
    success: function(data) {
      if (data.zoning && data.zoning.length) {
        display_zoning(data);
      }
      else {
        bootstrap_alert_danger(I18n.t('api_web.v01.zones.index.none_zones'));
      }
      progressBar && progressBar.done();
    },
    complete: completeWaiting,
    error: ajaxError
  });
}

Paloma.controller('ApiWeb/V01/Zone').prototype.index = function() {
  api_web_v01_zones_index(this.params);
};
