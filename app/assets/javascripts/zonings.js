// Copyright © Mapotempo, 2013-2015
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
var zonings_edit = function(params) {

  var zoning_id = params.zoning_id,
    planning_id = params.planning_id,
    vehicles_array = params.vehicles_array,
    vehicles_map = params.vehicles_map,
    url_click2call =  params.url_click2call,
    show_capacity = params.show_capacity;

  // sidebar has to be created before map
  var sidebar = L.control.sidebar('edit-zoning', {position: 'right'})
  sidebar.open('zoning');

  var map = mapInitialize(params);
  L.control.attribution({prefix: false, position: 'bottomleft'}).addTo(map);
  L.control.scale({
    imperial: false
  }).addTo(map);

  var fitBounds = (window.location.hash) ? false : true;
  new L.Hash(map);

  sidebar.addTo(map);

  var markersLayers = L.featureGroup(),
    stores_marker = L.featureGroup(),
    featureGroup = L.featureGroup();

  map.addLayer(featureGroup).addLayer(stores_marker).addLayer(markersLayers);

  var hasPlanning = false;
  var geoJsonLayers = {};

  var zone_map = {};

  new L.Control.Draw({
    draw: {
      polyline: false,
      polygon: {
        allowIntersection: false, // Restricts shapes to simple polygons
        shapeOptions: {
          color: '#707070'
        }
      },
      rectangle: false,
      circle: false,
      marker: false
    },
    edit: {
      featureGroup: featureGroup,
      edit: {
        selectedPathOptions: {
          maintainColor: true,
          dashArray: '10, 10'
        }
      }
    }
  }).addTo(map);

  map.on('draw:created', function(e) {
    add_zone({
      'vehicles': vehicles_array,
      'polygon': JSON.stringify(e.layer.toGeoJSON())
    }, e.layer);
  });

  map.on('draw:edited', function(e) {
    e.layers.eachLayer(function(layer) {
      update_zone(layer);
    });
  });

  map.on('draw:deleted', function(e) {
    e.layers.eachLayer(function(layer) {
      del_zone(layer);
    });
  });

  var count_point_in_polygon = function(layer_id, ele) {
    if (hasPlanning) {
      geoJsonLayer = geoJsonLayers[layer_id];
      var n = 0,
        quantity = 0;
      markersLayers.eachLayer(function(markerLayer) {
        if (leafletPip.pointInLayer(markerLayer.getLatLng(), geoJsonLayer, true).length > 0) {
          n += 1;
          if (markerLayer.data && markerLayer.data.quantity) {
            quantity += markerLayer.data.quantity;
          }
        }
      });
      $('.stop_number', ele).html(n);
      $('.quantity_number', ele).html(quantity);
      $('.stop').show(); // Display all
    }
  }

  var set_color = function(polygon, vehicle_id) {
    polygon.setStyle({
      color: (vehicle_id ? vehicles_map[vehicle_id].color : '#707070')
    });
  }

  var template = function(state) {
    if (state.id) {
      return $("<span><span class='color_small' style='background:" + vehicles_map[state.id].color + "'></span>&nbsp;" + vehicles_map[state.id].name + "</span>");
    } else {
      return I18n.t('web.form.empty_entry');
    }
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
    geoJsonLayers[geom._leaflet_id] = geoJsonLayer;

    featureGroup.addLayer(geom);

    zone.i18n = mustache_i18n;
    zone.vehicles = $.map(vehicles_map, function(val, i) {
      return {
        id: val.id,
        selected: val.id == zone.vehicle_id,
        name: val.name
      };
    });
    zone.show_capacity = show_capacity;
    if (show_capacity) {
      if (zone.vehicle_id && vehicles_map[zone.vehicle_id].capacity) {
        zone.capacity = vehicles_map[zone.vehicle_id].capacity;
      } else {
        zone.capacity = '-';
      }
    }
    $('#zones').append(SMT['zones/show'](zone));
    var ele = $('#zones .zone:last');
    ele.data('feature', zone);
    zone_map[geom._leaflet_id] = {
      layer: geom,
      ele: ele
    };
    count_point_in_polygon(geom._leaflet_id, ele);

    var formatNoMatches = I18n.t('web.select2.empty_result');
    $('select', ele).select2({
      minimumResultsForSearch: -1,
      templateResult: template,
      templateSelection: template,
      formatNoMatches: function() {
        return formatNoMatches;
      },
      escapeMarkup: function(m) {
        return m;
      }
    });

    $('select', ele).change(function(e) {
      if (e.added) {
        $.each($('#zones .zone select option[value=' + e.added.id + ']'), function(index, option) {
          option = $(option);
          var select = option.closest('select');
          var ee = option.closest('.zone');
          if (!ee.is(ele)) {
            option.prop('selected', false);
            select.trigger("change");
          }
        });
      }
      var val = e.val || e.target.value;
      geom.setStyle({
        color: (val.length > 0 ? vehicles_map[val].color : '#707070')
      });

      if (show_capacity) {
        if (this.value && vehicles_map[this.value].capacity) {
          $('.capacity_number', $(this).closest('.zone')).html(vehicles_map[this.value].capacity);
        } else {
          $('.capacity_number', $(this).closest('.zone')).html('-');
        }
      }
    });

    $('.delete', ele).click(function(event) {
      del_zone(geom);
    });
  }

  var del_zone = function(geom) {
    featureGroup.removeLayer(geom);
    var ele = zone_map[geom._leaflet_id].ele;
    ele.hide();
    ele.append('<input type="hidden" name="zoning[zones_attributes][][_destroy]" value="1"/>');
  }

  var update_zone = function(geom) {
    $('input[name=zoning\\[zones_attributes\\]\\[\\]\\[polygon\\]]', zone_map[geom._leaflet_id].ele).attr('value', JSON.stringify(geom.toGeoJSON()));
    count_point_in_polygon(geom._leaflet_id, zone_map[geom._leaflet_id].ele);
  }

  var planning = undefined;

  var display_zoning = function(data) {
    $('#zones').empty();
    featureGroup.clearLayers();
    $.each(data.zoning, function(index, zone) {
      var geom = L.geoJson(JSON.parse(zone.polygon));
      set_color(geom, zone.vehicle_id);
      add_zone(zone, geom);
    });

    if (fitBounds) {
      // var bounds = (planning ? markersLayers : featureGroup).getBounds();
      var bounds = (featureGroup.getLayers().length ?
        featureGroup :
        (markersLayers.getLayers().length ? markersLayers : stores_marker)
      ).getBounds();
      if (bounds && bounds.isValid()) {
        map.invalidateSize();
        map.fitBounds(bounds.pad(1.1), {
          maxZoom: 15,
          animate: false
        });
      }
    }
  }

  var display_zoning_first_time = function(data) {
    stores_marker.clearLayers();
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

    if (data.planning) {
      markersLayers.clearLayers();
      hasPlanning = true;
      $.each(data.planning, function(index, route) {
        $.each(route.stops, function(index, stop) {
          stop.i18n = mustache_i18n;
          if ($.isNumeric(stop.lat) && $.isNumeric(stop.lng)) {
            var m = L.marker(new L.LatLng(stop.lat, stop.lng), {
              icon: L.icon({
                iconUrl: '/images/' + (stop.icon || 'point') + '-' + (stop.color || (route.vehicle_id && vehicles_map[route.vehicle_id] ? vehicles_map[route.vehicle_id].color : '#707070')).substr(1) + '.svg',
                iconSize: new L.Point(12, 12),
                iconAnchor: new L.Point(6, 6),
                popupAnchor: new L.Point(0, -6),
              })
            }).addTo(stores_marker).bindPopup(SMT['stops/show']({
              stop: stop
            })).addTo(markersLayers);
            m.data = stop;
            m.on('mouseover', function(e) {
              m.openPopup();
            }).on('mouseout', function(e) {
              m.closePopup();
            }).on('popupopen', function(e){
              $('.phone_number', e.popup._container).click(function(e){
                phone_number_call(e.currentTarget.innerHTML, url_click2call, e.target);
              });
            });
          }
        });
      });
      planning = data.planning;
    }

    display_zoning(data);
  }

  $('form').submit(function (e) {
    var empty = false;
    $.each($('select').serializeArray(), function(i, e) {
      if (!e.value) {
        empty = true;
      }
    });
    if (empty && !confirm(I18n.t('zonings.edit.vehicleless_confirm'))) {
      return false;
    }
  });

  $('.automatic').click(function () {
    $.ajax({
      type: "patch",
      url: '/zonings/' + zoning_id + '/automatic' + (planning_id ? '/planning/' + planning_id : '') + '.json?n=' + $(this).data('n'),
      beforeSend: beforeSendWaiting,
      success: display_zoning,
      complete: completeAjaxMap,
      error: ajaxError
    });
  });

  $('#from_planning').click(function () {
    $.ajax({
      type: "patch",
      url: '/zonings/' + zoning_id + '/from_planning' + (planning_id ? '/planning/' + planning_id : '') + '.json',
      beforeSend: beforeSendWaiting,
      success: display_zoning,
      complete: completeAjaxMap,
      error: ajaxError
    });
  });

  $('#isochrone_size').timeEntry({
    show24Hours: true,
    spinnerImage: ''
  });

  $('#isochrone').click(function () {
    var vehicle_usage_set_id = $('#isochrone_vehicle_usage_set_id').val();
    var size = $('#isochrone_size').val().split(':');
    size = parseInt(size[0]) * 60 + parseInt(size[1]);
    $('#isochrone-progress-modal').modal({
      backdrop: 'static',
      keyboard: true
    });
    $('#isochrone-modal').modal('hide');
    $.ajax({
      type: "patch",
      url: '/zonings/' + zoning_id + '/isochrone.json?vehicle_usage_set_id=' + vehicle_usage_set_id + '&size=' + size,
      beforeSend: beforeSendWaiting,
      success: display_zoning,
      complete: function() {
        completeAjaxMap();
        $('#isochrone-progress-modal').modal('hide');
      },
      error: ajaxError
    });
  });

  $('#isodistance').click(function () {
    var vehicle_usage_set_id = $('#isodistance_vehicle_usage_set_id').val();
    var size = $('#isodistance_size').val();
    $('#isodistance-progress-modal').modal({
      backdrop: 'static',
      keyboard: true
    });
    $('#isodistance-modal').modal('hide');
    $.ajax({
      type: "patch",
      url: '/zonings/' + zoning_id + '/isodistance.json?vehicle_usage_set_id=' + vehicle_usage_set_id + '&size=' + size,
      beforeSend: beforeSendWaiting,
      success: display_zoning,
      complete: function() {
        completeAjaxMap();
        $('#isodistance-progress-modal').modal('hide');
      },
      error: ajaxError
    });
  });

  $.ajax({
    url: '/zonings/' + (zoning_id ? zoning_id + '/edit' : 'new') + (planning_id ? '/planning/' + planning_id : '') + '.json',
    beforeSend: beforeSendWaiting,
    success: display_zoning_first_time,
    complete: completeWaiting,
    error: ajaxError
  });
}

Paloma.controller('Zoning').prototype.new = function() {};

Paloma.controller('Zoning').prototype.create = function() {};

Paloma.controller('Zoning').prototype.edit = function() {
  zonings_edit(this.params);
};

Paloma.controller('Zoning').prototype.update = function() {
  zonings_edit(this.params);
};
