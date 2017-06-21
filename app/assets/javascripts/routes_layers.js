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

/******************
 * PopupModule
 *
 */
var popupModule = (function() {

  var _context,
    _previousMarker,
    _activeClickMarker,
    _currentAjaxRequested,
    _ajaxTimer = 100;

  var _ajaxCanBeProceeded = function() {
    var currentTime = (!Date.now) ? (new Date().getTime()) : Date.now(); // Ensure IE <9 compatibility
    if ((currentTime - _ajaxTimer) >= 100) {
      _ajaxTimer = currentTime;
      return true;
    }
    return false;
  };

  var _buildContentForPopup = function(marker) {
    if (_ajaxCanBeProceeded()) {
      getPopupContent(marker.properties.store_id ? 'store' : 'stop', marker.properties.store_id || {
        route_id: marker.properties.route_id,
        index: marker.properties.index
      }, function(content) {
        marker.getPopup().setContent(SMT['stops/show']($.extend(content, {
          number: marker.properties.route_id != _context.options.outOfRouteId && marker.properties.index
        })));
        return marker.getPopup()._container;
      });
      // Wait for ajax request
      _currentAjaxRequested.done(function() {
        marker.openPopup();
      });
    }
  };

  var getPopupContent = function(type, id, callback) {
    _currentAjaxRequested = $.ajax({
      url: _context.options.markerBaseUrl + (type == 'store' ?
        'stores/' + id + '.json' : 'routes/' + id.route_id + '/stops/by_index/' + id.index + '.json'),
      beforeSend: beforeSendWaiting,
      success: function(data) {
        data.i18n = mustache_i18n;
        data[type] = true;
        data.routes = _context.options.allRoutesWithVehicle; // unecessary to load all routes for each stop
        data.out_of_route_id = _context.options.outOfRouteId;
        var container = callback(data);
        if (container) {
          if (_context.options.url_click2call) {
            $('.phone_number', container).click(function(e) {
              phone_number_call(e.currentTarget.innerHTML, _context.options.url_click2call, e.target);
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
  };

  var createPopupForLayer = function(layer) {
    layer.bindPopup(L.responsivePopup({
      offset: layer.options.icon.options.iconSize.divideBy(2)
    }), {
      minWidth: 200,
      autoPan: false
    });
    _buildContentForPopup(layer);
  };

  var initializeModule = function(options, that) {
    _context = that;
  };

  var publicObject = {
    initGlobal: initializeModule,
    getPopupContent: getPopupContent,
    createPopupForLayer: createPopupForLayer,

    // PreviousMarker setter/getter
    get previousMarker() {
      return _previousMarker;
    },
    set previousMarker(value) {
      if (value instanceof L.Marker) {
        if (_previousMarker !== value) _previousMarker = value;
      } else {
        throw Error("Only Markers can be set in this variable");
      }
    },

    // activeClickMarker setter/getter
    get activeClickMarker() {
      return _activeClickMarker;
    },
    set activeClickMarker(value) {
      if (_activeClickMarker !== value) _activeClickMarker = value;
    }

  };

  return publicObject;

})();

function markerClusterIcon(childCount, defaultColor, borderColors) {
  var totalCountColors = 0;
  for (var colorCount in borderColors) {
    totalCountColors += borderColors[colorCount];
  }

  L.Icon.MarkerCluster = L.Icon.extend({
    options: {
      iconSize: new L.Point(36, 36),
      className: 'marker-cluster-multi-color leaflet-markercluster-icon'
    },
    createIcon: function() {
      var canvas = document.createElement('canvas');
      this._setIconStyles(canvas, 'icon');
      var iconSize = this.options.iconSize;
      canvas.width = iconSize.x;
      canvas.height = iconSize.y;
      this.draw(canvas.getContext('2d'), iconSize.x, iconSize.y);
      return canvas;
    },
    createShadow: function() {
      return null;
    },
    draw: function(canvas, width, height) {
      var borderSize = 6;
      var halfSize = width / 2 | 0;
      var start = 0;
      for (var colorValue in borderColors) {
        var size = borderColors[colorValue] / totalCountColors;

        if (size > 0) {
          canvas.beginPath();
          canvas.moveTo(halfSize, halfSize);
          canvas.fillStyle = colorValue;
          var from = start + 0.14,
            to = start + size * Math.PI * 2;
          if (to < from) {
            from = start;
          }
          canvas.arc(halfSize, halfSize, halfSize, from, to);
          start = start + size * Math.PI * 2;
          canvas.lineTo(halfSize, halfSize);
          canvas.fill();
          canvas.closePath();
        }
      }
      canvas.beginPath();
      canvas.fillStyle = defaultColor;
      canvas.arc(halfSize, halfSize, halfSize - borderSize, 0, Math.PI * 2);
      canvas.fill();
      canvas.closePath();
      canvas.fillStyle = 'white';
      canvas.textAlign = 'center';
      canvas.textBaseline = 'middle';
      canvas.font = '12px "Helvetica Neue", Arial, Helvetica, sans-serif';
      canvas.fillText(childCount, halfSize, halfSize, halfSize * 2 - borderSize);
    }
  });

  return new L.Icon.MarkerCluster();
}

var RoutesLayer = L.FeatureGroup.extend({
  options: {
    outOfRouteId: undefined,
    allRoutesWithVehicle: [],
    isochrone: false,
    isodistance: false,
    url_click2call: undefined,
    unit: 'km',
    markerBaseUrl: '/'
  },

  // Clusters for each route
  clustersByRoute: {},

  // Markers for each store
  markerStores: [],

  // Marker options
  markerOptions: {
    showCoverageOnHover: false,
    spiderfyOnMaxZoom: true,
    animate: false,
    maxClusterRadius: function(currentZoom) {
      return currentZoom >= 13 ? 1 : 30;
    },
    spiderfyDistanceMultiplier: 0.5,
    // disableClusteringAtZoom: 12,
    iconCreateFunction: function(cluster) {
      var currentZoom = cluster._map.getZoom();

      if (currentZoom >= 13) {
        var markers = cluster.getAllChildMarkers();
        var n = [markers[0].properties.index, markers.length === 2 ? markers[1].properties.index : '…'];
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

        return new L.divIcon({
          html: '<span class="fa-stack"><i class="fa fa-circle cluster-point-icon" style="color: ' + color + ';"></i><span class="fa-stack-1x point-icon-text">' + n.join(',') + '</span></span>',
          iconSize: new L.Point(24, 24),
          iconAnchor: new L.Point(12, 12),
          className: 'cluster-icon-container'
        });
      } else {
        var childCount = cluster.getChildCount();
        var routeColor = cluster.getAllChildMarkers()[0].properties.route_color || cluster.getAllChildMarkers()[0].properties.color;
        var countByColor = {};
        cluster.getAllChildMarkers().forEach(function(childMarker) {
          if (!countByColor[childMarker.properties.color]) {
            countByColor[childMarker.properties.color] = 1;
          } else {
            countByColor[childMarker.properties.color] += 1;
          }
        });

        if (Object.keys(countByColor).length > 1) {
          return markerClusterIcon(childCount, routeColor, countByColor);
        } else {
          return new L.DivIcon({
            html: '<div class="marker-cluster-icon" style="background-color: ' + routeColor + ';"><span>' + childCount + '</span></div>',
            className: 'marker-cluster marker-cluster-small',
            iconSize: new L.Point(40, 40)
          });
        }
      }
    }
  },

  initialize: function(planningId, options) {
    popupModule.initGlobal(null, this);
    L.FeatureGroup.prototype.initialize.call(this);
    this.planningId = planningId;
    this.options = $.extend(this.options, options);
  },

  onAdd: function(map) {
    L.FeatureGroup.prototype.onAdd.call(this, map);
    var self = this;
    this.layersByRoute = {};
    this.map = map;

    var onLoaded = function() {
      self.fire('initialLoad');
    };

    if (this.options.routeIds) {
      this._load(this.options.routeIds, true, undefined, onLoaded);
    } else {
      this._loadAll(onLoaded);
    }

    this.on('mouseover', function(e) {
      if (e.layer instanceof L.Marker && !popupModule.activeClickMarker) {
        // Unbind pop when needed | != compare memory adress between marker objects (Very same instance equality).

        if (popupModule.previousMarker && (popupModule.previousMarker != e.layer))
          popupModule.previousMarker.closePopup();

        if (e.layer.click)
          e.layer.click = false; // Don't forget to re-init e.layer.click

        if (!e.layer.getPopup()) {
          popupModule.createPopupForLayer(e.layer);
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
        popupModule.previousMarker = e.layer;
        if (!e.layer.click && e.layer.getPopup()) {
          e.layer.closePopup();
        }
      } else if (e.layer instanceof L.Path) {
        e.layer.setStyle({
          opacity: 0.5,
          weight: 5
        });
      }

      if (self.popupOpenTimer) {
        clearTimeout(self.popupOpenTimer);
      }
    })
    .on('click', function(e) {
      // Open popup if only one is actually in a click statement.
      if (e.layer instanceof L.Marker) {
        if (e.layer.properties.stop_id) {
          this.fire('clickStop', {
            stopId: e.layer.properties.stop_id
          });
        }
        if (e.layer.click) {
          if (e.layer === popupModule.activeClickMarker) {
            e.layer.closePopup();
            popupModule.activeClickMarker = void(0);
          }
          e.layer.click = false;
        } else {
          if (popupModule.activeClickMarker === void(0)) {
            if (!e.layer.getPopup()) {
              popupModule.createPopupForLayer(e.layer);
            } else {
              e.layer.openPopup();
            }
          } else if (e.layer !== popupModule.activeClickMarker) {
            popupModule.activeClickMarker.click = false;
            popupModule.activeClickMarker.closePopup()
              .unbindPopup();
            popupModule.createPopupForLayer(e.layer);
          }
          popupModule.activeClickMarker = e.layer;
          e.layer.click = true;
        }
      } else if (e.layer instanceof L.Path) {
        var distance = e.layer.properties.distance / 1000;
        var driveTime = e.layer.properties.drive_time;
        distance = (self.options.unit === 'km') ? distance.toFixed(1) + ' km' : (distance / 1.609344).toFixed(1) + ' miles';

        if (driveTime) {
          var driveTimeDay = null;
          if (driveTime > 3600 * 24) {
            driveTimeDay = driveTime / (3600 * 24) | 0;
          }
          driveTime = ('0' + parseInt(driveTime / 3600) % 24).slice(-2) + ':' + ('0' + parseInt(driveTime / 60) % 60).slice(-2) + ':' + ('0' + (driveTime % 60)).slice(-2);
          if (driveTimeDay) {
            driveTime += ' (' + I18n.t('plannings.edit.popup.day') + driveTimeDay + ')';
          }
        } else {
          driveTime = '';
        }

        var content = (driveTime ? '<div>' + I18n.t('plannings.edit.popup.stop_drive_time') + ' ' + driveTime + '</div>' : '') + '<div>' + I18n.t('plannings.edit.popup.stop_distance') + ' ' + distance + '</div>';
        L.responsivePopup({
          minWidth: 200,
          autoPan: false
        }).setLatLng(e.latlng).setContent(content).openOn(self.map);
      }
    }).on('popupopen', function(e) {
      // Silence is golden
    }).on('popupclose', function(e) {
      // Silence is golden
      popupModule.activeClickMarker = void(0);
    });
  },

  showRoutes: function(routeIds, geojson, callback) {
    this._load(routeIds, false, geojson, callback);
  },

  hideRoutes: function(routeIds) {
    this._removeRoutes(routeIds);
  },

  refreshRoutes: function(routeIds, geojson) {
    this._removeRoutes(routeIds);
    // FIXME: callback could be used to avoid blink
    this.showRoutes(routeIds, geojson);
  },

  showAllRoutes: function() {
    this.clearLayers();
    this._loadAll();
  },

  hideAllRoutes: function() {
    this.clearLayers();
    this.layersByRoute = {};
    this.clustersByRoute = {};
  },

  focus: function(options) {
    if (options.routeId && options.stopId) {
      var layers = this.layersByRoute[options.routeId];
      for (var i = 0; i < layers.length; i++) {
        if (layers[i] instanceof L.FeatureGroup) {
          this._focusOnMarkerInFeatureGroup(layers[i], 'stop_id', options.stopId);
          break;
        }
      }
    } else if (options.storeId) {
      this._focusOnMarkerInFeatureGroup(this.layerStores, 'store_id', options.storeId);
    }
  },

  _setViewForMarker: function(routeId, layer, id, marker) {
    if (this.map.getBounds().contains(marker.getLatLng())) {
      this.map.setView(marker.getLatLng(), this.map.getZoom(), {
        reset: true
      });
      popupModule.createPopupForLayer(marker);
    } else {
      if (!this.clustersByRoute[routeId].hasLayer(marker)) {
        marker.addTo(this.clustersByRoute[routeId]);
      }

      this.map.setView(marker.getLatLng(), 17, {
        reset: true
      });
      var cluster = this.clustersByRoute[routeId].getVisibleParent(marker);
      if (cluster && ('spiderfy' in cluster)) {
        cluster.spiderfy();
      }
      popupModule.createPopupForLayer(marker);
    }
  },

  _focusOnMarkerInFeatureGroup: function(layers, idName, id) {
    for (var routeId in this.clustersByRoute) {
      var markers = this.clustersByRoute[routeId].getLayers();
      for (var j = 0; j < markers.length; j++) {
        if (markers[j].properties[idName] === id) {
          this._setViewForMarker(routeId, layers, id, markers[j]);
          break;
        }
      }
    }
  },

  _load: function(routeIds, includeStores, geojson, callback) {
    if (!geojson) {
      var self = this;
      $.ajax({
        url: '/api/0.1/plannings/' + this.planningId + '/routes.geojson?geojson=polyline&ids=' + routeIds.join(',') + '&stores=' + includeStores,
        beforeSend: beforeSendWaiting,
        success: function(data) {
          self._addRoutes(data);
          if (callback) {
            callback();
          }
        },
        complete: completeAjaxMap,
        error: ajaxError
      });
    } else {
      this._addRoutes(geojson);
      if (callback) {
        callback();
      }
    }
  },

  _loadAll: function(callback) {
    var self = this;
    $.ajax({
      url: '/api/0.1/plannings/' + this.planningId + '.geojson?geojson=polyline',
      beforeSend: beforeSendWaiting,
      success: function(data) {
        self._addRoutes(data);
        if (callback) {
          callback();
        }
      },
      complete: completeAjaxMap,
      error: ajaxError
    });
  },

  _formatGeojsonFromPolylines: function(geojson) {
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
  },

  _addRoutes: function(geojson) {
    var self = this;

    self._formatGeojsonFromPolylines(geojson);

    var colorsByRoute = {};
    var overlappingMarkers = {};

    var layer = L.geoJSON(geojson, {
      onEachFeature: function(feature, layer) {
        if (feature.properties.route_id) {
          if (!(feature.properties.route_id in self.layersByRoute)) {
            self.layersByRoute[feature.properties.route_id] = [];
          }
          self.layersByRoute[feature.properties.route_id].push(layer);
        } else if (feature.properties.store_id) {
          self.layerStores = layer;
        }
        layer.properties = feature.properties;
      },
      style: function(feature) {
        if (!colorsByRoute[feature.properties.route_id]) {
          colorsByRoute[feature.properties.route_id] = feature.properties.color;
        }

        return {
          color: feature.properties.color,
          opacity: 0.5,
          weight: 5
        };
      },
      pointToLayer: function(geoJsonPoint, latlng) {
        var icon;
        var overlapKey = latlng.lat.toString() + latlng.lng.toString();

        var storeId = geoJsonPoint.properties.store_id;
        var routeId = geoJsonPoint.properties.route_id;

        // map.iconSize is defined in scaffold file
        if (storeId) {
          var storeIcon = geoJsonPoint.properties.icon || 'fa-home';
          var storeIconSize = geoJsonPoint.properties.icon_size || 'large';
          var storeColor = geoJsonPoint.properties.color || 'black';
          icon = L.divIcon({
            html: '<i class="fa ' + storeIcon + ' ' + self.map.iconSize[storeIconSize].name + ' store-icon" style="color: ' + storeColor + ';"></i>',
            iconSize: new L.Point(self.map.iconSize[storeIconSize].size, self.map.iconSize[storeIconSize].size),
            iconAnchor: new L.Point(self.map.iconSize[storeIconSize].size / 2, self.map.iconSize[storeIconSize].size / 2),
            className: 'store-icon-container'
          });
        } else {
          var pointIcon = geoJsonPoint.properties.icon || 'fa-circle';
          var pointIconSize = geoJsonPoint.properties.icon_size || 'medium';
          var pointColor = geoJsonPoint.properties.color || '#707070';
          var pointAnchor = new L.Point(self.map.iconSize[pointIconSize].size / 2, self.map.iconSize[pointIconSize].size / 2);
          if (overlappingMarkers[overlapKey] && overlappingMarkers[overlapKey] !== routeId) {
            pointAnchor = new L.Point(0, 0);
          } else {
            overlappingMarkers[overlapKey] = routeId;
          }

          icon = L.divIcon({
            html: '<span class="fa-stack"><i class="fa ' + pointIcon + ' ' + self.map.iconSize[pointIconSize].name + ' point-icon" style="color: ' + pointColor + ';"></i><span class="fa-stack-1x point-icon-text">' + ((geoJsonPoint.properties.active && geoJsonPoint.properties.route_id != self.options.outOfRouteId) ? geoJsonPoint.properties.index : '') + '</span></span>',
            iconSize: new L.Point(self.map.iconSize[pointIconSize].size, self.map.iconSize[pointIconSize].size),
            iconAnchor: pointAnchor,
            className: 'point-icon-container'
          });
        }

        var marker = L.marker(new L.LatLng(latlng.lat, latlng.lng), {
          icon: icon
        });
        marker.properties = geoJsonPoint.properties;
        // Add route color to each marker
        marker.properties.route_color = colorsByRoute[geoJsonPoint.properties.route_id];

        if (storeId) {
          self.markerStores.push(marker);
        } else {
          if (!self.clustersByRoute[routeId]) {
            self.clustersByRoute[routeId] = L.markerClusterGroup(self.markerOptions);
          }
          self.clustersByRoute[routeId].addLayer(marker);
        }
        return marker;
      }
    });

    // Add only route polylines to map
    layer.addTo(this.map);

    // Add marker clusters
    for (var routeId in this.clustersByRoute) {
      this.addLayer(this.clustersByRoute[routeId]);
    }

    // Add store markers
    for (var storeId in self.markerStores) {
      this.addLayer(self.markerStores[storeId]);
    }
  },

  _removeRoutes: function(routeIds) {
    var that = this;
    routeIds.forEach(function(routeId) {
      if (routeId in that.layersByRoute) {
        that.removeLayer(that.layersByRoute[routeId]);
        delete that.layersByRoute[routeId];
      }
      if (routeId in that.clustersByRoute) {
        that.removeLayer(that.clustersByRoute[routeId]);
        delete that.clustersByRoute[routeId];
      }
    });
  }
});
