// Copyright © Mapotempo, 2017
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

var RoutesLayer = L.FeatureGroup.extend({
  options: {
    isochrone: false,
    isodistance: false,
    url_click2call: undefined,
    unit: 'km',
    markerBaseUrl: '/'
  },

  // Keep track of pevious popup
  previousMarker: void(0),

  initialize: function(planningId, options) {
    L.FeatureGroup.prototype.initialize.call(this);
    this.planningId = planningId;
    this.options = $.extend(this.options, options);
  },

  onAdd: function(map) {
    L.FeatureGroup.prototype.onAdd.call(this, map);
    var self = this;
    this.layersRouteId = {};
    this.map = map;

    var loadCallBack = function() {
      self.fire('initialLoad');
    };

    if (this.options.routeIds) {
      this.load(this.options.routeIds, true, undefined, loadCallBack);
    } else {
      this.loadAll(loadCallBack);
    }

    this.on('mouseover', function(e) {
      if (e.layer instanceof L.Marker) {
        // Unbind pop when needed | != compare memory adress between marker objects (Very same instance equality).
        if(self.previousMarker && (self.previousMarker != e.layer)) self.previousMarker.unbindPopup();
        if (!e.layer.getPopup()) {
          this.createPopupForLayer(e.layer);
        } else if (!e.layer.getPopup().isOpen()) {
          e.layer.openPopup();
        }
      } else if (e.layer instanceof L.Path) {
        e.layer.setStyle({
          opacity: 0.9,
          weight: 7
        });
      }
    }).on('mouseout', function(e) {
      if (e.layer instanceof L.Marker) {
        self.previousMarker = e.layer;
        if (!e.layer.click) {
          e.layer.closePopup();
        }
      } else if (e.layer instanceof L.Path) {
        e.layer.setStyle({
          opacity: 0.5,
          weight: 5
        });
      }
    })
    .on('click', function(e) {
      if (e.layer instanceof L.Marker) {
        if (e.layer.properties.stop_id) {
          this.fire('clickStop', {
            stopId: e.layer.properties.stop_id
          });
        }
        if (e.layer.click) {
          e.layer.closePopup();
          e.layer.click = false;
        } else {
          e.layer.click = true;
          e.layer.openPopup();
        }
      } else if (e.layer instanceof L.Path) {
        var distance = e.layer.properties.distance / 1000;
        var driveTime = e.layer.properties.drive_time;
        distance = (self.options.unit == 'km') ? distance.toFixed(1) + ' km' : (distance / 1.609344).toFixed(1) + ' miles';
        driveTime = (driveTime !== null) ? ('0' + parseInt(driveTime / 3600) % 24).slice(-2) + ':' + ('0' + parseInt(driveTime / 60) % 60).slice(-2) + ':' + ('0' + (driveTime % 60)).slice(-2) : '';
        var content = (driveTime ? '<div>' + I18n.t('plannings.edit.popup.stop_drive_time') + ' ' + driveTime + '</div>' : '') + '<div>' + I18n.t('plannings.edit.popup.stop_distance') + ' ' + distance + '</div>';
        L.popup({
          minWidth: 200,
          autoPan: false
        }).setLatLng(e.latlng).setContent(content).openOn(self.map);
      }
    }).on('popupopen', function(e) {
      // Wait a bit before make ajax call, avoid too many ajax call
      setTimeout(function() {
        // The popup still open ?
        if (e.popup.isOpen()) {
          self.buildPopupContent(e.layer.properties.type || 'stop', e.layer.properties.store_id || e.layer.properties.stop_id, function(content) {
            if (e.popup.isOpen()) {
              e.popup.setContent(SMT['stops/show']($.extend(content, {
                number: e.layer.properties.index
              })));
              return e.popup._container;
            }
          });
        }
      }, 100);
    }).on('popupclose', function(e) {
      e.layer.click = false;
    });

    // Empty layer required to create empty cluster
    var layer = L.featureGroup([]);

    this.clusterSmallZoom = L.markerClusterGroup({
      showCoverageOnHover: false,
      spiderfyOnMaxZoom: false,
      animate: false,
      disableClusteringAtZoom: 12
    });
    this.clusterSmallZoom.addLayer(layer);

    this.clusterLargeZoom = L.markerClusterGroup({
      showCoverageOnHover: false,
      animate: false,
      maxClusterRadius: 1,
      spiderfyDistanceMultiplier: 0.5,
      iconCreateFunction: function(cluster) {
        var markers = cluster.getAllChildMarkers();
        var n = [markers[0].properties.index, markers.length == 2 ? markers[1].properties.index : '…'];
        var color;
        if (markers.length > 50) {
          color = markers[0].properties.color;
        } else {
          var colors = {};
          var max = 0;
          for (var i = 0; i < markers.length; i++) {
            var count = colors[markers[i].properties.color] ? colors[markers[i].properties.color] + 1 : 1;
            if (count > max) {
              max = count;
              color = markers[i].properties.color;
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
    this.clusterLargeZoom.addLayer(layer);

    this.map.on('zoomend', L.bind(this.setClusterByZoom, this));
    this.setClusterByZoom();
  },

  buildPopupContent: function(type, id, callBack) {
    var self = this;
    $.ajax({
      url: self.options.markerBaseUrl + (type == 'store' ?
        'stores/' + id + '.json' : 'stops/' + id + '.json'),
      beforeSend: beforeSendWaiting,
      success: function(data) {
        data.i18n = mustache_i18n;
        data[type] = true;
        var container = callBack(data);
        if (container) {
          if (self.options.url_click2call) {
            $('.phone_number', container).click(function(e) {
              phone_number_call(e.currentTarget.innerHTML, self.options.url_click2call, e.target);
            });
          }
          $('[data-target$=isochrone-modal]', container).click(function(e) {
            $('#isochrone_lat').val(data.lat);
            $('#isochrone_lng').val(data.lng);
            $('#isochrone_vehicle_usage_id').val(data.vehicle_usage_id);
          });
          $('[data-target$=isodistance-modal]', container).click(function(e) {
            $('#isodistance_lat').val(data.lat);
            $('#isodistance_lng').val(data.lng);
            $('#isodistance_vehicle_usage_id').val(data.vehicle_usage_id);
          });
        }
      },
      complete: completeAjaxMap,
      error: ajaxError
    });
  },

  setClusterByZoom: function(e) {
    if (this.map.getZoom() >= 17) {
      this.removeLayer(this.clusterSmallZoom);
      this.addLayer(this.clusterLargeZoom);
    } else {
      this.removeLayer(this.clusterLargeZoom);
      this.addLayer(this.clusterSmallZoom);
    }
  },

  routesShow: function(e, geojson, callBack) {
    this.load(e.routeIds, false, geojson, callBack);
  },

  getPopRouteLayers: function(routeIds) {
    var routeLayers = [];
    for (var j = 0; j < routeIds.length; j++) {
      var id = routeIds[j];
      if (id in this.layersRouteId) {
        var layers = this.layersRouteId[id];
        for (var i = 0; i < layers.length; i++) {
          routeLayers.push(layers[i]);
        }
        delete this.layersRouteId[id];
      }
    }
    return routeLayers;
  },

  routesHide: function(e) {
    var routeLayers = this.getPopRouteLayers(e.routeIds);
    this.clusterSmallZoom.removeLayers(routeLayers);
    this.clusterLargeZoom.removeLayers(routeLayers);
  },

  routesRefresh: function(e, geojson) {
    var routeLayers = this.getPopRouteLayers(e.routeIds);

    var self = this;
    this.routesShow(e, geojson, function() {
      self.clusterSmallZoom.removeLayers(routeLayers);
      self.clusterLargeZoom.removeLayers(routeLayers);
    });
  },

  routesShowAll: function(e, geojson) {
    this.clearLayers();
    this.loadAll();
  },

  routesHideAll: function(e, geojson) {
    this.clearLayers();
    this.layersRouteId = {};
  },

  focus: function(e) {
    if (e.routeId && e.stopId) {
      var layers = this.layersRouteId[e.routeId];
      for (var i = 0; i < layers.length; i++) {
        if (layers[i] instanceof L.FeatureGroup) {
          this.focusOnMarkerInFeatureGroup(layers[i], 'stop_id', e.stopId);
          break;
        }
      }
    } else if (e.storeId) {
      this.focusOnMarkerInFeatureGroup(this.layerStores, 'store_id', e.storeId);
    }
  },

  setViewForMarker: function(layer, id, marker) {
      if (this.map.getBounds().contains(marker.getLatLng())) {
        this.map.setView(marker.getLatLng(), this.map.getZoom(), { reset: true });
        this.createPopupForLayer(marker);
      } else {

        if (!this.clusterSmallZoom.hasLayer(marker))
          marker.addTo(this.clusterSmallZoom);

        this.map.setView(marker.getLatLng(), 17, { reset: true });
        var cluster = this.clusterSmallZoom.getVisibleParent(marker);
        if (cluster && ('spiderfy' in cluster)) cluster.spiderfy();
        this.createPopupForLayer(marker);

      }
  },

  focusOnMarkerInFeatureGroup: function(layers, idName, id) {
    var markers = this.clusterSmallZoom.getLayers();
    for (var j = 0; j < markers.length; j++) {
      if (markers[j].properties[idName] == id) {
        this.setViewForMarker(layers, id, markers[j]);
        break;
      }
    }
  },

  createPopupForLayer: function(layer) {
    layer.bindPopup('', {
      minWidth: 200,
      autoPan: false
    }).openPopup();
  },

  load: function(routeIds, includeStores, geojson, callBack) {
    if (!geojson) {
      var self = this;
      $.ajax({
        url: '/api/0.1/plannings/' + this.planningId + '/routes.geojson?geojson=polyline&ids=' + routeIds.join(',') + '&stores=' + includeStores,
        beforeSend: beforeSendWaiting,
        success: function(data) {
          self.addRoutes(data);
          if (callBack) {
            callBack();
          }
        },
        complete: completeAjaxMap,
        error: ajaxError
      });
    } else {
      this.addRoutes(geojson);
      if (callBack) {
        callBack();
      }
    }
  },

  loadAll: function(callBack) {
    var self = this;
    $.ajax({
      url: '/api/0.1/plannings/' + this.planningId + '.geojson?geojson=polyline',
      beforeSend: beforeSendWaiting,
      success: function(data) {
        self.addRoutes(data);
        if (callBack) {
          callBack();
        }
      },
      complete: completeAjaxMap,
      error: ajaxError
    });
  },

  addRoutes: function(geojson) {
    var self = this;

    for (var i = 0; i < geojson.features.length; i++) {
      if (geojson.features[i].geometry.polylines) {
        var feature = geojson.features[i];
        feature.geometry.coordinates = L.PolylineUtil.decode(feature.geometry.polylines, 6);
        for (var j = 0; j < feature.geometry.coordinates.length; j++) {
          feature.geometry.coordinates[j] = [feature.geometry.coordinates[j][1], feature.geometry.coordinates[j][0]];
        }
        delete feature.geometry.polylines;
      }
    }

    var layer = L.geoJSON(geojson, {
      onEachFeature: function(feature, layer) {
        if (feature.properties.route_id) {
          if (!(feature.properties.route_id in self.layersRouteId)) {
            self.layersRouteId[feature.properties.route_id] = [];
          }
          self.layersRouteId[feature.properties.route_id].push(layer);
        } else if (feature.properties.type == 'store') {
          self.layerStores = layer;
        }
        layer.properties = feature.properties;
      },
      style: function(feature) {
        return {
          color: feature.properties.color,
          opacity: 0.5,
          weight: 5
        };
      },
      pointToLayer: function(geoJsonPoint, latlng) {
        for (var i = 0; i < geoJsonPoint.geometry.coordinates.length; i++) {
          if (geoJsonPoint.properties.points[i] && geoJsonPoint.geometry.coordinates[i][0] == latlng.lng && geoJsonPoint.geometry.coordinates[i][1] == latlng.lat) {
            var point = geoJsonPoint.properties.points[i];
            geoJsonPoint.properties.points[i] = undefined;
            point.type = geoJsonPoint.properties.type;
            point.index = i + 1;
            point.route_id = geoJsonPoint.properties.route_id;
            point.color = point.color || geoJsonPoint.properties.color || (point.type == 'store' ? 'black' : '#707070');
            point.icon = point.icon || geoJsonPoint.properties.icon || (point.type == 'store' ? 'fa-home' : 'point');
            point.icon_size = point.icon_size || geoJsonPoint.properties.icon_size || 'large';
            break;
          }
        }
        if (point.type == 'store') {
          var icon = L.divIcon({
            html: '<i class="fa ' + point.icon + ' ' + self.map.iconSize[point.icon_size].name + ' store-icon" style="color: ' + point.color + ';"></i>',
            iconSize: new L.Point(self.map.iconSize[point.icon_size || 'large'].size, self.map.iconSize[point.icon_size || 'large'].size),
            iconAnchor: new L.Point(self.map.iconSize[point.icon_size || 'large'].size / 2, self.map.iconSize[point.icon_size || 'large'].size / 2),
            popupAnchor: new L.Point(0, -Math.floor(self.map.iconSize[point.icon_size || 'large'].size / 2.5)),
            className: 'store-icon-container'
          });
        } else {
          point.route = geoJsonPoint.properties;
          var icon = new L.NumberedDivIcon({
            number: point.index,
            iconUrl: '/images/' + point.icon + '-' + point.color.substr(1) + '.svg',
            iconSize: new L.Point(12, 12),
            iconAnchor: new L.Point(6, 6),
            popupAnchor: new L.Point(0, -6),
            className: "small"
          });
        }
        var marker = L.marker(new L.LatLng(latlng.lat, latlng.lng), {
          icon: icon
        });
        marker.properties = point;
        return marker;
      }
    });
    this.clusterSmallZoom.addLayers(layer.getLayers());
    this.clusterLargeZoom.addLayers(layer.getLayers());

    this.setClusterByZoom();
  }
});
