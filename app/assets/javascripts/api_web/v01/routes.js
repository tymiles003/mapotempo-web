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

var api_web_v01_routes_index = function(params) {
  var progressBar = Turbolinks.enableProgressBar();
  progressBar.advanceTo(25);

  var planning_id = params.planning_id,
    map_layer_url = params.map_layer_url,
    map_lat = params.map_lat,
    map_lng = params.map_lng,
    map_attribution = params.map_attribution,
    route_ids = params.route_ids,
    vehicles_map = params.vehicles_map,
    map = new L.Map('map', {
      attributionControl: false
    }).setView([map_lat, map_lng], 13),
    markers = {},
    stores = {},
    layers = {},
    layers_cluster = {},
    routes_layers,
    routes_layers_cluster;

  L.control.attribution({prefix: false}).addTo(map);

  L.control.scale({
    imperial: false
  }).addTo(map);

  var caption = L.DomUtil.get('routes-caption');
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

  routes_layers = L.featureGroup();
  routes_layers_cluster = L.featureGroup();
  map.addLayer(routes_layers);

  map.on('zoomend', function(e) {
    if (map.getZoom() >= 17) {
      map.removeLayer(routes_layers);
      map.addLayer(routes_layers_cluster);
    } else {
      map.removeLayer(routes_layers_cluster);
      map.addLayer(routes_layers);
    }
  });

  L.tileLayer(map_layer_url, {
    maxZoom: 18,
    attribution: map_attribution
  }).addTo(map);

  var display_planning = function(data) {
    $.each(data.routes, function(i, route) {
      if (route.vehicle_id) {
        route.vehicle = vehicles_map[route.vehicle_id];
      }
    });

    data.i18n = mustache_i18n;
    data.planning_id = data.id;
    $("#planning").html(SMT['plannings/edit'](data));


    var stores_marker = L.featureGroup();
    stores = {};
    $.each(data.stores, function(i, store) {
      store.store = true;
      store.planning_id = data.planning_id;
      if ($.isNumeric(store.lat) && $.isNumeric(store.lng)) {
        var m = L.marker(new L.LatLng(store.lat, store.lng), {
          icon: L.icon({
            iconUrl: '/images/marker-home' + (store.color ? ('-' + store.color.substr(1)) : '') + '.svg',
            iconSize: new L.Point(32, 32),
            iconAnchor: new L.Point(16, 16),
            popupAnchor: new L.Point(0, -12)
          })
        }).addTo(stores_marker).bindPopup(SMT['stops/show']({stop: store}), {
          minWidth: 200,
          autoPan: false
        });
        m.on('mouseover', function(e) {
          m.openPopup();
        }).on('mouseout', function(e) {
          if (!m.click) {
            m.closePopup();
          }
        }).off('click').on('click', function(e) {
          if (m.click) {
            m.closePopup();
          } else {
            m.click = true;
            m.openPopup();
          }
        }).on('popupclose', function(e) {
          m.click = false;
        });
        stores[store.id] = m;
      }
    });
    stores_marker.addTo(map);


    $.each(data.routes, function(i, route) {
      var color = route.vehicle ? route.vehicle.color : '#707070';
      var vehicle_name;
      if (route.vehicle) {
        vehicle_name = route.vehicle.name;
      }

      routes_layers.removeLayer(layers[route.route_id]);
      routes_layers_cluster.removeLayer(layers_cluster[route.route_id]);
      layers[route.route_id] = L.featureGroup();
      layers_cluster[route.route_id] = new L.MarkerClusterGroup({
        showCoverageOnHover: false,
        maxClusterRadius: 1,
        spiderfyDistanceMultiplier: 0.5,
        iconCreateFunction: function(cluster) {
          var markers = cluster.getAllChildMarkers();
          var n = [], i;
          for (i = 0; i < markers.length; i++) {
            if (markers[i].number) {
              if (n.length < 2) {
                n.push(markers[i].number);
              } else {
                n = [n[0], "…"];
                break;
              }
            }
          }
          return new L.NumberedDivIcon({
            number: n.join(","),
            iconUrl: '/images/point_large-' + color.substr(1) + '.svg',
            iconSize: new L.Point(24, 24),
            iconAnchor: new L.Point(12, 12),
            popupAnchor: new L.Point(0, -12),
            className: "large"
          });
        }
      });

      $.each(route.stops, function(index, stop) {
        if (stop.trace) {
          var polyline = new L.Polyline(L.PolylineUtil.decode(stop.trace, 6));
          L.polyline(polyline.getLatLngs(), {
            color: color
          }).addTo(layers[route.route_id]);
          L.polyline(polyline.getLatLngs(), {
            offset: 3,
            color: color
          }).addTo(layers_cluster[route.route_id]);
        }
        if (stop.destination && $.isNumeric(stop.lat) && $.isNumeric(stop.lng)) {
          stop.i18n = mustache_i18n;
          stop.color = stop.destination.color || color;
          stop.vehicle_name = vehicle_name;
          stop.route_id = route.route_id;
          stop.routes = data.routes;
          stop.planning_id = data.planning_id;
          var m = L.marker(new L.LatLng(stop.lat, stop.lng), {
            icon: new L.NumberedDivIcon({
              number: stop.number,
              iconUrl: '/images/' + (stop.destination.icon || 'point') + '-' + stop.color.substr(1) + '.svg',
              iconSize: new L.Point(12, 12),
              iconAnchor: new L.Point(6, 6),
              popupAnchor: new L.Point(0, -6),
              className: "small"
            })
          }).addTo(layers[route.route_id]).addTo(layers_cluster[route.route_id]).bindPopup(SMT['stops/show']({stop: stop}), {
            minWidth: 200,
            autoPan: false
          });
          m.number = stop.number;
          m.on('mouseover', function(e) {
            m.openPopup();
          }).on('mouseout', function(e) {
            if (!m.click) {
              m.closePopup();
            }
          }).off('click').on('click', function(e) {
            if (m.click) {
              m.closePopup();
            } else {
              m.click = true;
              m.openPopup();
            }
          }).on('popupclose', function(e) {
            m.click = false;
          });
          markers[stop.stop_id] = m;
        }
      });
      if (route.store_stop && route.store_stop.stop_trace) {
        var polyline = new L.Polyline(L.PolylineUtil.decode(route.store_stop.stop_trace, 6));
        L.polyline(polyline.getLatLngs(), {
          color: color
        }).addTo(layers[route.route_id]).addTo(layers_cluster[route.route_id]);
      }

      routes_layers_cluster.addLayer(layers_cluster[route.route_id]);
      routes_layers.addLayer(layers[route.route_id]);
    });
  }

  var display_planning_first_time = function(data) {
    $.each(data.routes, function(i, route) {
      layers[route.route_id] = L.featureGroup();
      layers_cluster[route.route_id] = L.featureGroup();
    });
    display_planning(data);
    var bounds = routes_layers.getBounds();
    if (bounds && bounds.isValid()) {
      map.fitBounds(bounds.pad(1.1), {
        maxZoom: 15
      });
    }
  }

  progressBar.advanceTo(50);
  queryParam = (route_ids) ? ('?' + $.param({ids: route_ids.join(',')})) : '';
  $.ajax({
    url: '/api-web/0.1/plannings/' + planning_id + '/routes.json' + queryParam,
    beforeSend: beforeSendWaiting,
    success: function(data) {
      if (data.routes && data.routes.length) {
        display_planning_first_time(data);
      }
      else {
        bootstrap_alert_danger(I18n.t('api_web.v01.routes.index.none_routes'));
      }
      progressBar.done();
    },
    complete: completeWaiting,
    error: ajaxError
  });
}

Paloma.controller('ApiWeb/V01/Route').prototype.index = function() {
  api_web_v01_routes_index(this.params);
};
