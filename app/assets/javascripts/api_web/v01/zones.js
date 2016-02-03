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

  map.markersLayers = L.featureGroup();
  map.storesLayers = L.featureGroup();
  var featureGroup = L.featureGroup();

  map.addLayer(featureGroup).addLayer(map.storesLayers).addLayer(map.markersLayers);

  var set_color = function(polygon, vehicle_id) {
    polygon.setStyle({
      color: (vehicle_id ? params.vehicles_map[vehicle_id].color : '#707070')
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
    api_web_v01_display_destinations_('destinations', map, data);

    map.storesLayers.clearLayers();
    $.each(data.stores, function(i, store) {
      store.store = true;
      store.i18n = mustache_i18n;
      if ($.isNumeric(store.lat) && $.isNumeric(store.lng)) {
        var m = L.marker(new L.LatLng(store.lat, store.lng), {
          icon: L.divIcon({
            html: '<i class="fa ' + (store.icon || 'fa-home') + ' ' + map.iconSize[store.icon_size || 'large'].name + ' store-icon" style="color: ' + (store.color || 'black') + ';"></i>',
            iconSize: new L.Point(map.iconSize[store.icon_size || 'large'].size, map.iconSize[store.icon_size || 'large'].size),
            iconAnchor: new L.Point(map.iconSize[store.icon_size || 'large'].size / 2, map.iconSize[store.icon_size || 'large'].size / 2),
            popupAnchor: new L.Point(0, -Math.floor(map.iconSize[store.icon_size || 'large'].size / 2.5)),
            className: 'store-icon-container'
          })
        }).addTo(map.storesLayers).bindPopup(SMT['stops/show']({
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
  var ajaxParams = {};
  if (params.zone_ids) ajaxParams.ids = params.zone_ids.join(',');
  if (params.destinations) ajaxParams.destinations = params.destinations;
  if (params.destination_ids && !params.destinations) ajaxParams.destination_ids = params.destination_ids.join(',');
  if (params.vehicle_usage_set_id) ajaxParams.vehicle_usage_set_id = params.vehicle_usage_set_id;
  if (params.store_ids) ajaxParams.store_ids = params.store_ids.join(',');
  $.ajax({
    url: '/api-web/0.1/zonings/' + params.zoning_id + '/zones.json',
    method: params.method,
    data: ajaxParams,
    beforeSend: beforeSendWaiting,
    success: function(data) {
      if (data.zoning && data.zoning.length) {
        display_zoning(data);
      }
      else {
        stickyError(I18n.t('api_web.v01.zones.index.none_zones'));
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
