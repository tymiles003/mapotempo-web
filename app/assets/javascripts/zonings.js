// Copyright © Mapotempo, 2013-2016
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
    url_click2call = params.url_click2call,
    show_capacity = params.show_capacity;

  var changes = {};
  var drawing_changed, editing_drawing;

  // sidebar has to be created before map
  var sidebar = L.control.sidebar('edit-zoning', {
    position: 'right'
  })
  sidebar.open('zoning');

  var map = mapInitialize(params);
  L.control.attribution({
    prefix: false,
    position: 'bottomleft'
  }).addTo(map);
  L.control.scale({
    imperial: false
  }).addTo(map);

  var fitBounds = window.location.hash ? false : true;
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

  function checkZoningChanges(e) {
    var zones_changed;
    $.each(changes, function(i, array) {
      if (array.length > 0) zones_changed = true;
    });
    if (editing_drawing || drawing_changed || zones_changed) {
      if (!confirm(I18n.t('plannings.edit.page_change_zoning_confirm'))) {
        e.preventDefault();
      }
    }
    $(document).on('page:change', function(e) {
      $(document).off('page:before-change', checkZoningChanges);
    });
  }

  $(document).on('page:before-change', checkZoningChanges);

  map.on('draw:editstart', function(e) {
    editing_drawing = true;
  });

  map.on('draw:editstop', function(e) {
    editing_drawing = true;
  });

  map.on('draw:created', function(e) {
    drawing_changed = true;
    addZone({
      'vehicles': vehicles_array,
      'polygon': JSON.stringify(e.layer.toGeoJSON())
    }, e.layer);
  });

  map.on('draw:edited', function(e) {
    editing_drawing = null;
    drawing_changed = true;
    e.layers.eachLayer(function(layer) {
      updateZone(layer);
    });
  });

  map.on('draw:deleted', function(e) {
    drawing_changed = true;
    e.layers.eachLayer(function(layer) {
      deleteZone(layer);
      labelLayer.clearLayers();
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
  };

  var setColor = function(polygon, vehicle_id, speed_multiplicator) {
    polygon.setStyle((speed_multiplicator === 0) ? {
      color: '#FF0000',
      fillColor: '#707070',
      weight: 5,
      dashArray: '10, 10',
      fillPattern: stripes
    } : {
      color: ((vehicle_id && vehicles_map[vehicle_id]) ? vehicles_map[vehicle_id].color : '#707070'),
      fillColor: null,
      weight: 2,
      dashArray: 'none',
      fillPattern: null
    });
  };
  var stripes = new L.StripePattern({
    color: '#FF0000',
    angle: -45
  });
  stripes.addTo(map);

  var template = function(state) {
    if (state.id && vehicles_map[state.id]) {
      return $("<span><span class='color_small' style='background:" + vehicles_map[state.id].color + "'></span>&nbsp;" + vehicles_map[state.id].name + "</span>");
    } else {
      return I18n.t('web.form.empty_entry');
    }
  };

  var router_avoid_zones = $.grep(vehicles_array, function(elem) {
    return elem.router_avoid_zones;
  }).length > 0;

  var labelLayer = (new L.layerGroup()).addTo(map);
  var zoneGeometry = L.GeoJSON.extend({
    addOverlay: function(zone) {
      var that = this;
      var labelMarker;
      this.on('mouseover', function(e) {
        that.setStyle({
          opacity: 0.9,
          weight: (zone.speed_multiplicator === 0) ? 5 : 3
        });
        if (zone.name) {
          labelMarker = L.marker(that.getBounds().getCenter(), {
            icon: L.divIcon({
              className: 'label',
              html: zone.name,
              iconSize: [100, 40]
            })
          }).addTo(labelLayer);
        }
      });
      this.on('mouseout', function(e) {
        that.setStyle({
          opacity: 0.5,
          weight: (zone.speed_multiplicator === 0) ? 5 : 2
        });
        if (labelMarker) {
          labelLayer.removeLayer(labelMarker);
        }
        labelMarker = null;
      });
      this.on('click', function(e) {
        if (!zone.id) {
          return;
        }
        var z = $('#zones input[value=' + zone.id + ']').closest('.zone');
        z.css('box-shadow', '#4D90FE 0px 0px 5px');
        setTimeout(function() {
          z.css('box-shadow', '');
        }, 1500);
        $('.sidebar-content').animate({
          scrollTop: z.offset().top + $('.sidebar-content').scrollTop() - 100
        });
      });
      return this;
    }
  });

  var addZone = function(zone, geom) {

    function observeChanges(element) {

      var zone_id = getID();

      if (zone_id == '') return;

      function getID() {
        return $(element).find("input[name='zoning[zones_attributes][][id]']").val();
      }

      function toggleChange(k, v) {
        if (params.zoning_details[zone_id][k] == v) {
          $.each(changes[zone_id], function(i, item) { if (item == k) changes[zone_id].splice(i, 1) });
        } else {
          if ($.inArray(k, changes[zone_id]) == -1) changes[zone_id].push(k);
        }
      }

      changes[zone_id] = [];

      element.find('input.zone-name').change(function(e) {
        toggleChange('name', $(e.target).val());
      });

      element.find('.avoid-zone input[type=checkbox]').click(function(e) {
        toggleChange('avoid_zone', $(e.target).is(':checked'));
      });

      element.find('select.vehicle_select').change(function(e) {
        toggleChange('vehicle_id', $(e.target).val());
      });
    }

    var geoJsonLayer;
    if (geom instanceof L.GeoJSON) {
      geoJsonLayer = geom;
      geom = geom.getLayers()[0];
    } else {
      geoJsonLayer = (new zoneGeometry).addOverlay(zone);
      geoJsonLayer.addLayer(geom);
    }
    geoJsonLayers[geom._leaflet_id] = geoJsonLayer;

    featureGroup.addLayer(geom);

    zone.i18n = mustache_i18n;
    zone.vehicles = $.map(vehicles_array, function(val, i) {
      return {
        id: val.id,
        selected: val.id == zone.vehicle_id,
        name: val.name
      };
    });
    if (zone.vehicle_id && $.inArray(true, $.map(zone.vehicles, function(val, i) {
        return val.selected;
      })) < 0) {
      zone.vehicles.unshift({
        id: vehicles_map[zone.vehicle_id].id,
        selected: true,
        name: vehicles_map[zone.vehicle_id].name
      });
    }
    zone.avoid_zone = zone.speed_multiplicator == 0;
    zone.router_avoid_zones = zone.vehicle_id && vehicles_map[zone.vehicle_id] ? vehicles_map[zone.vehicle_id].router_avoid_zones : router_avoid_zones;
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

    observeChanges(ele);

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
      var vehicleId = e.val || e.target.value;

      var avoid_zones = router_avoid_zones;
      if (vehicleId) {
        avoid_zones = vehicles_map[vehicleId].router_avoid_zones;
      }
      if (!avoid_zones) {
        $('input[name=zoning\\[zones_attributes\\]\\[\\]\\[avoid_zone\\]]', $(this).closest('.zone')).prop('disabled', true);
        $('.avoid-zone', $(this).closest('.zone')).addClass('disabled');
      } else {
        $('input[name=zoning\\[zones_attributes\\]\\[\\]\\[avoid_zone\\]]', $(this).closest('.zone')).prop('disabled', false);
        $('.avoid-zone', $(this).closest('.zone')).css({
          display: 'block'
        });
        $('.avoid-zone', $(this).closest('.zone')).removeClass('disabled');
      }

      setColor(geom, vehicleId, ($('[name$=\\[avoid_zone\\]]', ele).is(':checked') && !$('[name$=\\[avoid_zone\\]]', ele).is(':disabled')) ? 0 : undefined);

      if (show_capacity) {
        if (this.value && vehicles_map[this.value].capacity) {
          $('.capacity_number', $(this).closest('.zone')).html(vehicles_map[this.value].capacity);
        } else {
          $('.capacity_number', $(this).closest('.zone')).html('-');
        }
      }
    });

    $('[name$=\\[avoid_zone\\]]', ele).change(function(e) {
      setColor(geom, $('select', ele).val(), e.target.checked ? 0 : undefined);
    });

    $('.delete', ele).click(function(event) {
      deleteZone(geom);
    });
  };

  var deleteZone = function(geom) {
    drawing_changed = true;
    featureGroup.removeLayer(geom);
    var ele = zone_map[geom._leaflet_id].ele;
    ele.hide();
    ele.append('<input type="hidden" name="zoning[zones_attributes][][_destroy]" value="1"/>');
  };

  var updateZone = function(geom) {
    $('input[name=zoning\\[zones_attributes\\]\\[\\]\\[polygon\\]]', zone_map[geom._leaflet_id].ele).attr('value', JSON.stringify(geom.toGeoJSON()));
    count_point_in_polygon(geom._leaflet_id, zone_map[geom._leaflet_id].ele);
  };

  var planning = undefined;

  var displayZoning = function(data) {
    nbZones = data.zoning.length;
    $('#zones').empty();
    featureGroup.clearLayers();
    $.each(data.zoning, function(index, zone) {
      var geom = (new zoneGeometry(JSON.parse(zone.polygon))).addOverlay(zone);
      if (geom) {
        setColor(geom, zone.vehicle_id, zone.speed_multiplicator);
        addZone(zone, geom);
      }
    });

    if (fitBounds) {
      // var bounds = (planning ? markersLayers : featureGroup).getBounds();
      var bounds = (featureGroup.getLayers().length ?
        featureGroup :
        (markersLayers.getLayers().length ? markersLayers : stores_marker)
      ).getBounds();
      if (bounds && bounds.isValid()) {
        map.invalidateSize();
        map.fitBounds(bounds, {
          maxZoom: 15,
          animate: false,
          padding: [20, 20]
        });
      }
    }
  };

  var displayDestinations = function(route) {
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
        }).bindPopup(SMT['stops/show']({
          stop: stop
        })).addTo(markersLayers);
        m.data = stop;
        m.on('mouseover', function(e) {
          m.openPopup();
        }).on('mouseout', function(e) {
          m.closePopup();
        }).on('popupopen', function(e) {
          $('.phone_number', e.popup._container).click(function(e) {
            phone_number_call(e.currentTarget.innerHTML, url_click2call, e.target);
          });
        });
      }
    });
  };

  var displayZoningFirstTime = function(data) {
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
        displayDestinations(route);
      });
      planning = data.planning;
    }

    displayZoning(data);
  };

  $('form').submit(function(e) {
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

  var destLoaded = false;
  $('[name=all-destinations]').change(function() {
    if ($(this).is(':checked')) {
      if (!destLoaded) {
        $.ajax({
          type: 'get',
          url: '/destinations.json',
          beforeSend: beforeSendWaiting,
          success: function(data) {
            destLoaded = true;
            displayDestinations({
              stops: data.destinations
            });
          },
          complete: completeAjaxMap,
          error: ajaxError
        });
      } else {
        map.addLayer(markersLayers);
      }
      $('.automatic.disabled').each(function() {
        $(this).removeClass('disabled');
      });
      $('#generate').css('display', 'inline-block');
    } else {
      map.removeLayer(markersLayers);
      $('.automatic').each(function() {
        $(this).addClass('disabled');
      });
    }
  });

  var nbZones = undefined;

  $('.automatic').click(function() {
    if (!$(this).hasClass('disabled')) {
      if (nbZones && !confirm(I18n.t('zonings.edit.generate_confirm'))) {
        return false;
      }
      $.ajax({
        type: "patch",
        url: '/zonings/' + zoning_id + '/automatic' + (planning_id ? '/planning/' + planning_id : '') + '.json?n=' + $(this).data('n'),
        beforeSend: beforeSendWaiting,
        success: displayZoning,
        complete: completeAjaxMap,
        error: ajaxError
      });
    }
  });

  $('#from_planning').click(function() {
    if (nbZones && !confirm(I18n.t('zonings.edit.generate_confirm'))) {
      return false;
    }
    $.ajax({
      type: "patch",
      url: '/zonings/' + zoning_id + '/from_planning' + (planning_id ? '/planning/' + planning_id : '') + '.json',
      beforeSend: beforeSendWaiting,
      success: displayZoning,
      complete: completeAjaxMap,
      error: ajaxError
    });
  });

  $('#isochrone_size').timeEntry({
    show24Hours: true,
    spinnerImage: ''
  });

  $('#isochrone').click(function() {
    if (nbZones && !confirm(I18n.t('zonings.edit.generate_confirm'))) {
      return false;
    }
    var vehicle_usage_set_id = $('#isochrone_vehicle_usage_set_id').val();
    var size = $('#isochrone_size').val().split(':');
    size = parseInt(size[0]) * 60 + parseInt(size[1]);

    $.ajax({
      url: '/zonings/' + zoning_id + '/isochrone',
      type: "patch",
      dataType: "json",
      data: {
        vehicle_usage_set_id: vehicle_usage_set_id,
        size: size
      },
      beforeSend: function(jqXHR, settings) {
        beforeSendWaiting();
        $('#isochrone-modal').modal('hide');
        $('#isochrone-progress-modal').modal({
          backdrop: 'static',
          keyboard: true
        });
      },
      success: function(data, textStatus, jqXHR) {
        hideNotices();
        displayZoning(data);
        notice(I18n.t('zonings.edit.success'));
      },
      complete: function(jqXHR, textStatus) {
        completeAjaxMap();
        $('#isochrone-progress-modal').modal('hide');
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('zonings.edit.failed'));
      }
    });
  });

  $('#isodistance').click(function() {
    if (nbZones && !confirm(I18n.t('zonings.edit.generate_confirm'))) {
      return false;
    }
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
      success: displayZoning,
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
    success: displayZoningFirstTime,
    complete: completeWaiting,
    error: ajaxError
  });
};

Paloma.controller('Zonings', {
  edit: function() {
    zonings_edit(this.params);
  },
  update: function() {
    zonings_edit(this.params);
  }
});
