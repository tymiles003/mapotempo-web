// Copyright © Mapotempo, 2013-2017
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

var zonings_edit = function(params) {
  'use strict';

  var prefered_unit = params.prefered_unit,
    zoning_id = params.zoning_id,
    planning_id = params.planning_id,
    vehicles = params.vehicles_array,
    vehiclesMap = params.vehicles_map,
    url_click2call = params.url_click2call,
    deliverableUnits = params.deliverable_units,
    showUnits = params.show_deliverable_units;

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

  sidebar.addTo(map);

  var unplannedMarkers = L.featureGroup(),
    withVehicleMarkers = L.featureGroup(),
    storeMarkers = L.featureGroup(),
    featureGroup = L.featureGroup();

  map.addLayer(featureGroup).addLayer(storeMarkers).addLayer(withVehicleMarkers).addLayer(unplannedMarkers);

  var destinationsDisplayed = false;
  var zonesMap = {};

  // Must be init before L.Hash
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

  var fitBounds = window.location.hash ? false : true;
  // FIXME when turbolinks get updated
  if (navigator.userAgent.indexOf("Edge") == -1) map.addHash();
  var removeHash = function() {
    map.removeHash();
    $(document).off('page:before-change', removeHash);
  }
  $(document).on('page:before-change', removeHash);

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

  map.on(L.Draw.Event.EDITSTART, function(e) {
    editing_drawing = true;
  });

  map.on(L.Draw.Event.EDITSTOP, function(e) {
    editing_drawing = true;
  });

  map.on(L.Draw.Event.CREATED, function (e) {
    drawing_changed = true;
    addZone({
      'vehicles': vehicles,
      'polygon': JSON.stringify(e.layer.toGeoJSON())
    }, e.layer);
  });

  map.on(L.Draw.Event.EDITED, function(e) {
    editing_drawing = null;
    drawing_changed = true;
    e.layers.eachLayer(function(layer) {
      updateZone(layer);
    });
  });

  map.on(L.Draw.Event.DELETED, function(e) {
    drawing_changed = true;
    e.layers.eachLayer(function(layer) {
      deleteZone(layer);
      labelLayer.clearLayers();
    });
  });

  var countPointInPolygon = function(layer, ele) {
    if (destinationsDisplayed) {
      var n = 0,
        quantities = {};
      $.each($.merge(withVehicleMarkers.getLayers(), $('#hide_out_of_route').is(':checked') ? [] : unplannedMarkers.getLayers()), function(i, markerLayer) {
        if (leafletPip.pointInLayer(markerLayer.getLatLng(), layer, true).length > 0) {
          n += 1;
          if (markerLayer.data) {
            $.each(markerLayer.data.quantities, function(i, q) {
              quantities[q.deliverable_unit_id] = quantities[q.deliverable_unit_id] ? (quantities[q.deliverable_unit_id] + q.quantity) : q.quantity;
            });
          }
        }
      });
      $('.stop_number', ele).html(n);
      $('span[data-unit-id]', ele).hide();
      for (var key in quantities) {
        if (quantities[key]) $('span[data-unit-id="' + key + '"]', ele).show();
        $('span[data-unit-id="' + key + '"] .quantity_number', ele).html(quantities[key]);
      }
      $('.zone-info').show(); // Display all
    }
  };

  var setColor = function(polygon, vehicle_id, speed_multiplicator) {
    polygon.setStyle((speed_multiplicator === 0) ? {
      color: '#FF0000',
      fillColor: '#707070',
      opacity: 0.5,
      weight: 5,
      dashArray: '10, 10',
      fillPattern: stripes
    } : {
      color: ((vehicle_id && vehiclesMap[vehicle_id]) ? vehiclesMap[vehicle_id].color : '#707070'),
      fillColor: null,
      opacity: 0.5,
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
    if (state.id && vehiclesMap[state.id]) {
      return $("<span><span class='color_small' style='background:" + vehiclesMap[state.id].color + "'></span>&nbsp;" + vehiclesMap[state.id].name + "</span>");
    } else {
      return I18n.t('web.form.empty_entry');
    }
  };

  var router_avoid_zones = $.grep(vehicles, function(elem) {
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

      var zone_id = $(element).find("input[name='zoning[zones_attributes][][id]']").val();
      if (zone_id == '') return;

      function toggleChange(k, v) {
        if (params.zoning_details[zone_id] && params.zoning_details[zone_id][k] == v) {
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

    featureGroup.addLayer(geom);

    zone.i18n = mustache_i18n;
    $.each(params.manage_zoning, function(i, elt) {
      zone['manage_' + elt] = true;
    });
    zone.vehicles = $.map(vehicles, function(val, i) {
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
        id: vehiclesMap[zone.vehicle_id].id,
        selected: true,
        name: vehiclesMap[zone.vehicle_id].name
      });
    }
    zone.avoid_zone = zone.speed_multiplicator == 0;
    zone.router_avoid_zones = zone.vehicle_id && vehiclesMap[zone.vehicle_id] ? vehiclesMap[zone.vehicle_id].router_avoid_zones : router_avoid_zones;
    zone.show_deliverable_units = showUnits;
    if (showUnits) {
      if (zone.vehicle_id)
        zone.deliverable_units = vehiclesMap[zone.vehicle_id].capacities;
      else
        zone.deliverable_units = deliverableUnits;
    }

    $('#zones').append(SMT['zones/show'](zone));

    var ele = $('#zones .zone:last');

    observeChanges(ele);

    ele.data('feature', zone);
    zonesMap[geom._leaflet_id] = {
      layer: geoJsonLayer,
      ele: ele
    };
    countPointInPolygon(geoJsonLayer, ele);

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

      if (vehicleId ? vehiclesMap[vehicleId].router_avoid_zones : router_avoid_zones) {
        $('input[name=zoning\\[zones_attributes\\]\\[\\]\\[avoid_zone\\]]', $(this).closest('.zone')).prop('disabled', false);
        $('.avoid-zone', $(this).closest('.zone')).css({
          display: 'block'
        });
        $('.avoid-zone', $(this).closest('.zone')).removeClass('disabled');
      }
      else {
        $('input[name=zoning\\[zones_attributes\\]\\[\\]\\[avoid_zone\\]]', $(this).closest('.zone')).prop('disabled', true);
        $('.avoid-zone', $(this).closest('.zone')).addClass('disabled');
      }

      setColor(geom, vehicleId, ($('[name$=\\[avoid_zone\\]]', ele).is(':checked') && !$('[name$=\\[avoid_zone\\]]', ele).is(':disabled')) ? 0 : undefined);

      if (showUnits) {
        $('.capacity_number', $(this).closest('.zone')).html('-');
        if (this.value) {
          var that = this;
          $.each(vehiclesMap[this.value].capacities, function(index, capacity) {
            if (capacity.capacity) {
              $('[data-unit-id=' + capacity.unit_id + '] .capacity_number', $(that).closest('.zone')).html(capacity.capacity);
            }
          });
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
    var ele = zonesMap[geom._leaflet_id].ele;
    ele.hide();
    ele.append('<input type="hidden" name="zoning[zones_attributes][][_destroy]" value="1"/>');
  };

  var updateZone = function(geom) {
    $('input[name=zoning\\[zones_attributes\\]\\[\\]\\[polygon\\]]', zonesMap[geom._leaflet_id].ele).attr('value', JSON.stringify(geom.toGeoJSON()));
    countPointInPolygon(zonesMap[geom._leaflet_id].layer, zonesMap[geom._leaflet_id].ele);
  };

  var planning = undefined;

  var displayZoning = function(data) {
    nbZones = data.zoning && data.zoning.length;
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
      var bounds = (featureGroup.getLayers().length ?
        featureGroup :
        unplannedMarkers.getLayers().length ?
        unplannedMarkers :
        withVehicleMarkers.getLayers().length ?
        withVehicleMarkers :
        storeMarkers
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
    destinationsDisplayed = true
    var hasVehicle = route.vehicle_id && vehiclesMap[route.vehicle_id];

    $.each(route.stops, function(index, stop) {
      stop.i18n = mustache_i18n;
      stop.visits = true;
      if ($.isNumeric(stop.lat) && $.isNumeric(stop.lng)) {
        var m = L.marker(new L.LatLng(stop.lat, stop.lng), {
          icon: L.icon({
            iconUrl: '/images/' + (stop.icon || 'point') + '-' + (stop.color || (hasVehicle ? vehiclesMap[route.vehicle_id].color : '#707070')).substr(1) + '.svg',
            iconSize: new L.Point(12, 12),
            iconAnchor: new L.Point(6, 6),
            popupAnchor: new L.Point(0, -6),
          })
        }).bindPopup(SMT['stops/show']({
          stop: stop
        }));

        if (hasVehicle) m.addTo(withVehicleMarkers);
        else m.addTo(unplannedMarkers);

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
        }).addTo(storeMarkers).bindPopup(SMT['stops/show']({
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
            var visits = [];
            $.each(data.destinations, function(i, dest) {
              if (dest.visits.length) {
                $.each(dest.visits, function(i, visit) {
                  visits.push($.extend(dest, visit));
                });
              }
              else {
                visits.push(dest);
              }
            });
            displayDestinations({
              stops: visits
            });
            $.each(featureGroup.getLayers(), function(idx, zone) {
              countPointInPolygon(zonesMap[zone._leaflet_id].layer, zonesMap[zone._leaflet_id].ele);
            });
          },
          complete: completeAjaxMap,
          error: ajaxError
        });
      } else {
        map.addLayer(unplannedMarkers);
        $('.zone-info').show();
      }
      $('.automatic.disabled').each(function() {
        $(this).removeClass('disabled');
      });
      $('#generate').css('display', 'inline-block');
    } else {
      map.removeLayer(unplannedMarkers);
      $('.zone-info').hide();
      $('.automatic').each(function() {
        $(this).addClass('disabled');
      });
    }
  });

  $('#hide_out_of_route').change(function(e) {
    if ($(e.target).is(':checked')) {
      map.removeLayer(unplannedMarkers);
    } else {
      map.addLayer(unplannedMarkers);
    }
    $.each(featureGroup.getLayers(), function(idx, zone) {
      countPointInPolygon(zonesMap[zone._leaflet_id].layer, zonesMap[zone._leaflet_id].ele);
    });
  });

  var nbZones = undefined;

  $('.automatic').click(function() {
    if (!$(this).hasClass('disabled')) {
      if (nbZones && !confirm(I18n.t('zonings.edit.generate_confirm'))) {
        return false;
      }
      $.ajax({
        type: "patch",
        url: '/zonings/' + zoning_id + '/automatic' + (planning_id ? '/planning/' + planning_id : '') + '.json',
        data: {
          n: $(this).data('n'),
          hide_out_of_route: $("#hide_out_of_route").is(":checked") ? 1 : 0
        },
        beforeSend: beforeSendWaiting,
        success: function(data) {
          fitBounds = true;
          displayZoning(data);
        },
        complete: function(jqXHR, textStatus) {
          completeAjaxMap();
        },
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
    spinnerImage: '',
    defaultTime: '00:00'
  });

  $('#isochrone').click(function() {
    if (nbZones && !confirm(I18n.t('zonings.edit.generate_confirm'))) {
      return false;
    }
    var size = $('#isochrone_size').val().split(':');
    size = parseInt(size[0]) * 60 + parseInt(size[1]);

    $.ajax({
      url: '/zonings/' + zoning_id + '/isochrone',
      type: "patch",
      dataType: "json",
      data: {
        vehicle_usage_set_id: $('#isochrone_vehicle_usage_set_id').val(),
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
        fitBounds = true;
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
    var isodistanceSize = parseFloat($('#isodistance_size').val().replace(/,/g, '.'));
    var size = (prefered_unit == 'km') ? isodistanceSize : Math.ceil10(isodistanceSize * 1.60934, -2);

    $('#isodistance-progress-modal').modal({
      backdrop: 'static',
      keyboard: true
    });
    $('#isodistance-modal').modal('hide');
    $.ajax({
      type: "patch",
      url: '/zonings/' + zoning_id + '/isodistance.json?vehicle_usage_set_id=' + $('#isodistance_vehicle_usage_set_id').val() + '&size=' + size,
      beforeSend: beforeSendWaiting,
      success: function(data) {
        fitBounds = true;
        displayZoning(data);
      },
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
