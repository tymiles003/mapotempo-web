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
var plannings_form = function() {
  $('#planning_date').datepicker({
    language: I18n.currentLocale(),
    autoclose: true,
    calendarWeeks: true,
    todayHighlight: true,
    format: I18n.t("all.datepicker"),
    zIndexOffset: 1000
  });

  var formatNoMatches = I18n.t('web.select2.empty_result');
  $('select[name=planning\\[tag_ids\\]\\[\\]]').select2({
    theme: 'bootstrap',
    minimumResultsForSearch: -1,
    templateSelection: templateTag,
    templateResult: templateTag,
    formatNoMatches: function() {
      return formatNoMatches;
    },
    width: '100%'
  });
};

var plannings_new = function(params) {
  plannings_form();
  $("#planning_zoning_ids").select2({
    theme: 'bootstrap'
  });
};

var plannings_edit = function(params) {
  plannings_form();

  var planning_id = params.planning_id,
    planning_ref = params.planning_ref,
    user_api_key = params.user_api_key,
    zoning_ids = params.zoning_ids,
    routes_array = params.routes_array,
    vehicles_array = params.vehicles_array,
    vehicles_usages_map = params.vehicles_usages_map,
    url_click2call = params.url_click2call,
    colors = params.colors,
    layer_zoning,
    markers = {},
    stores = {},
    layers = {},
    layers_cluster = {},
    routes_layers,
    routes_layers_cluster,
    zoning_ids = getZonings();

  function getZonings() {
    return $("#planning_zoning_ids").val() || [];
  }

  function eqArrays(a, b) {
    return (a.length == b.length) && a.every(function(item, index) {
      return item === b[index];
    });
  }

  var apply_zoning_modal = bootstrap_dialog({
    title: I18n.t('plannings.edit.dialog.zoning.title'),
    icon: 'fa-bars',
    message: SMT['modals/default_with_progress']({
      msg: I18n.t('plannings.edit.dialog.zoning.in_progress')
    })
  });

  $('.update-zonings-form').submit(function(e) {
    e.preventDefault();
    if (!confirm(I18n.t('plannings.edit.zoning_confirm'))) { return };
    $.ajax({
      url: $(e.target).attr('action'),
      type: 'PATCH',
      data: { planning: { zoning_ids: getZonings() }},
      dataType: 'json',
      beforeSend: function(jqXHR) {
        apply_zoning_modal.modal('show');
      },
      complete: function(xhr, status) {
        apply_zoning_modal.modal('hide');
      },
      success: function(data, textStatus, jqXHR) {
        updatePlanning(data, {
          'partial': false
        });
        $('.update-zonings-form button[type=submit]').removeClass('btn-warning').addClass('btn-default').removeAttr('title');
        notice(I18n.t('plannings.edit.zonings.success'));
        zoning_ids = getZonings();
      },
      error: function(jqXHR, textStatus, errorThrown) {
        stickyError(I18n.t('plannings.edit.zonings.fail'));
      }
    });
  });

  var allRoutesVehicles = $.map(routes_array, function(route) {
    if (route.vehicle_usage_id) {
      var vehicle_usage = {};
      $.each(vehicles_usages_map, function(i, v) {
        if (v.vehicle_usage_id == route.vehicle_usage_id) {
          vehicle_usage = v;
        }
      });
      route.name = (route.ref ? (route.ref + ' ') : '') + vehicle_usage.name;
      if (!route.color) {
        route.color = vehicle_usage.color;
      }
    }
    return route;
  });

  // sidebar has to be created before map
  var sidebar = L.control.sidebar('edit-planning', {
    position: 'right'
  });
  sidebar.open('planning-pane');

  var vehicleIdsPosition = vehicles_array.filter(function(vehicle) {
    return vehicle.available_position;
  }).map(function(vehicle) {
    return vehicle.id;
  });

  var vehicleLayer, tid;
  var vehicleMarkers = [];

  var displayVehicles = function(data) {
    data.forEach(function(pos) {
      if ($.isNumeric(pos.lat) && $.isNumeric(pos.lng)) {
        var route = routes_array.filter(function(route) {
          return route.vehicle_usage_id == vehicles_usages_map[pos.vehicle_id].vehicle_usage_id;
        })[0];
        var isMoving = pos.speed && (Date.parse(pos.time) > Date.now() - 600 * 1000);
        var direction_icon = pos.direction ? '<i class="fa fa-location-arrow fa-stack-1x vehicle-direction" style="transform: rotate(' + (parseInt(pos.direction) - 45) + 'deg);" />' : '';
        var iconContent = isMoving ?
          '<span class="fa-stack" data-route_id="' + route.route_id + '"><i class="fa fa-truck fa-stack-2x vehicle-icon pulse" style="color: ' + (route.color || vehicles_usages_map[pos.vehicle_id].color) + '"></i>' + direction_icon + '</span>' :
          '<i class="fa fa-truck fa-lg vehicle-icon" style="color: ' + (route.color || vehicles_usages_map[pos.vehicle_id].color) + '"></i>';
        vehicleLayer.removeLayer(vehicleMarkers[pos.vehicle_id]);
        vehicleMarkers[pos.vehicle_id] = L.marker(new L.LatLng(pos.lat, pos.lng), {
          icon: new L.divIcon({
            html: iconContent,
            iconSize: new L.Point(24, 24),
            iconAnchor: new L.Point(12, 12),
            popupAnchor: new L.Point(0, -12),
            className: 'vehicle-position'
          }),
          title: vehicles_usages_map[pos.vehicle_id].name + ' - ' + pos.device_name + ' - ' + I18n.t('plannings.edit.vehicle_speed') + ' ' + (pos.speed || 0) + 'km/h - ' + I18n.t('plannings.edit.vehicle_last_position_time') + ' ' + (pos.time_formatted || (new Date(pos.time)).toLocaleString()),
        }).addTo(vehicleLayer);
      }
    });
  };

  var queryVehicles = function() {
    $.ajax({
      type: 'GET',
      url: '/api/0.1/vehicles/current_position.json',
      data: {
        ids: vehicleIdsPosition
      },
      dataType: 'json',
      beforeSend: beforeSendWaiting,
      success: function(data, textStatus, jqXHR) {
        if (data && data.errors) {
          clearInterval(tid);
          $.each(data.errors, function(i, error) {
            stickyError(I18n.t('plannings.edit.position') + " " + error);
          });
        } else {
          displayVehicles(data);
        }
      },
      complete: completeAjaxMap,
      error: function(err) {
        clearInterval(tid);
      }
    });
  };

  if (vehicleIdsPosition.length) {
    vehicleLayer = L.featureGroup();
    queryVehicles();
    tid = setInterval(queryVehicles, 30000);
    $(document).on('page:before-change', function() {
      clearInterval(tid);
    });
    if (!params.overlay_layers) params.overlay_layers = {};
    params.overlay_layers[I18n.t("plannings.edit.vehicles")] = vehicleLayer;
  }

  params.geocoder = true;

  var map = mapInitialize(params);

  if (vehicleLayer) map.addLayer(vehicleLayer);

  L.control.attribution({
    prefix: false,
    position: 'bottomleft'
  }).addTo(map);
  L.control.scale({
    imperial: false
  }).addTo(map);

  var fitBounds = (window.location.hash) ? false : true;
  new L.Hash(map);

  sidebar.addTo(map);

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

  $.each(routes_array, function(i, route) {
    layers[route.route_id] = L.featureGroup();
    layers_cluster[route.route_id] = L.featureGroup();
  });

  $.each($('#lock_routes_dropdown li a'), function(i, element) {
    $(element).click(function(e) {

      if (routes_array.length == 0) return;

      var selection = $(element).parent('li').data('selection');

      // Params
      var array = [];
      $.each(routes_array, function(index, route) {
        array.push(route.route_id)
      });
      array.push($('#out_of_route').parents('[data-route_id]').data('route_id'));

      $.ajax({
        url: '/api/0.1/plannings/' + planning_id + '/update_routes',
        type: 'PATCH',
        data: {
          route_ids: array,
          selection: selection,
          action: 'lock'
        },
        dataType: 'json',
        beforeSend: beforeSendWaiting,
        complete: completeAjaxMap,
        error: ajaxError,
        success: function(data, textStatus, jqXHR) {

          $.each(data, function(index, route) {
            var element = $("[data-route_id='" + route.id + "']");
            if (route.locked) {
              element.find(".lock").removeClass("btn-default").addClass("btn-warning");
              element.find('.lock i').removeClass('fa-unlock').addClass('fa-lock');
            } else {
              element.find(".lock").removeClass("btn-warning").addClass("btn-default");
              element.find('.lock i').removeClass('fa-lock').addClass('fa-unlock');
            }
          });

        }
      });

    });
  });

  $.each($('#toggle_routes_dropdown li a'), function(i, element) {
    $(element).click(function(e) {

      if (routes_array.length == 0) return;

      var selection = $(element).parent('li').data('selection');

      // Params
      var array = [];
      $.each(routes_array, function(index, route) {
        array.push(route.route_id)
      });
      array.push($('#out_of_route').parents('[data-route_id]').data('route_id'));

      $.ajax({
        url: '/api/0.1/plannings/' + planning_id + '/update_routes',
        type: 'PATCH',
        data: {
          route_ids: array,
          selection: selection,
          action: 'toggle'
        },
        dataType: 'json',
        beforeSend: beforeSendWaiting,
        complete: completeAjaxMap,
        error: ajaxError,
        success: function(data, textStatus, jqXHR) {

          $.each(data, function(index, route) {
            var element = $("[data-route_id='" + route.id + "']");
            if (route.hidden) {
              element.find("ul.stops").hide();
              element.find('.toggle i').removeClass('fa-eye').addClass('fa-eye-slash');
              routes_layers.removeLayer(layers[route.id]);
              routes_layers_cluster.removeLayer(layers_cluster[route.id]);
            } else {
              element.find("ul.stops").show();
              element.find('.toggle i').removeClass('fa-eye-slash').addClass('fa-eye');
              routes_layers.addLayer(layers[route.id]);
              routes_layers_cluster.addLayer(layers_cluster[route.id]);
            }
          });

        }
      });

    });
  });

  var enlighten_stop = function(stop_id) {
    var e = $(".routes [data-stop_id='" + stop_id + "']");
    e.css("background", "orange");
    setTimeout(function() {
      e.css("background", "");
    }, 1500);

    if (e.offset().top < 0 || e.offset().top > $(".sidebar-content").height()) {
      $(".sidebar-content").animate({
        scrollTop: e.offset().top + $(".sidebar-content").scrollTop() - 100
      });
    }
  };

  layer_zoning = (new L.LayerGroup()).addTo(map);
  var zoneGeometry = L.GeoJSON.extend({
    addOverlay: function(zone) {
      var that = this;
      var labelLayer = (new L.layerGroup()).addTo(map);
      var labelMarker;
      this.on('mouseover', function(e) {
        that.setStyle({
          opacity: 0.9,
          weight: (zone.speed_multiplicator === 0) ? 5 : 3
        });
        if (zone.name) labelMarker = L.marker(that.getBounds().getCenter(), {
          icon: L.divIcon({
            className: 'label',
            html: zone.name,
            iconSize: [100, 40]
          })
        }).addTo(labelLayer);
      });
      this.on('mouseout', function(e) {
        that.setStyle({
          opacity: 0.5,
          weight: (zone.speed_multiplicator === 0) ? 5 : 2
        });
        if (labelMarker) labelLayer.removeLayer(labelMarker);
        labelMarker = null
      });
      return this;
    }
  });

  var displayZoning = function(zoning) {
    $.each(zoning.zones, function(index, zone) {
      var geoJsonLayer = (new zoneGeometry(JSON.parse(zone.polygon))).addOverlay(zone);
      var geom = geoJsonLayer.getLayers()[0];
      if (geom) {
        geom.setStyle((zone.speed_multiplicator === 0) ? {
          color: '#FF0000',
          fillColor: '#707070',
          weight: 5,
          dashArray: '10, 10',
          fillPattern: stripes
        } : {
          color: (zone.vehicle_id && vehicles_usages_map[zone.vehicle_id] ? vehicles_usages_map[zone.vehicle_id].color : '#707070'),
          fillColor: null,
          weight: 2,
          dashArray: 'none',
          fillPattern: null
        });
        geom.addTo(layer_zoning);
      }
    });
  };
  var stripes = new L.StripePattern({
    color: '#FF0000',
    angle: -45
  });
  stripes.addTo(map);

  var templateSelectionZoning = function(state) {
    if (state.id)
      return $('<span><span class="zoning_name">' + state.text + '</span> <a href="/zonings/' + state.id + '/edit/planning/' + planning_id + '?back=true" title="' + I18n.t('plannings.edit.zoning_edit') + '"><i class="fa fa-pencil fa-fw"></i></a></span>');
  }

  $("#planning_zoning_ids").select2({
    theme: 'bootstrap',
    templateSelection: templateSelectionZoning
  });
  $("#planning_zoning_ids").change(function() {
    layer_zoning.clearLayers();
    var ids = $(this).val();
    if (ids && ids.length > 0) {
      $.each(ids, function(i, id) {
        $.ajax({
          type: "get",
          url: "/api/0.1/zonings/" + id + ".json",
          beforeSend: beforeSendWaiting,
          success: displayZoning,
          complete: completeAjaxMap,
          error: ajaxError
        });
      });
    }
  });

  var dialog_optimizer;

  initOptimizerDialog();

  function initOptimizerDialog() {
    hideNotices(); // Clear Failed Optimization Notices
    dialog_optimizer = bootstrap_dialog({
      title: I18n.t('plannings.edit.dialog.optimizer.title'),
      icon: 'fa-gear',
      message: SMT['modals/optimize']({
        i18n: mustache_i18n
      })
    });
  };

  var errorOptimize = function(data) {
    $('body').removeClass('ajax_waiting');
    stickyError(I18n.t('plannings.edit.optimize_failed'));
  };

  var successOptimize = function(data) {
    $('body').removeClass('ajax_waiting');
    notice(I18n.t('plannings.edit.optimize_complete'));
  };

  $("#optimize_each, #optimize_global").click(function(event, ui) {
    if (!confirm(I18n.t($(this).data('opti-global') ? 'plannings.edit.optimize_global_confirm' : 'plannings.edit.optimize_each_confirm'))) {
      return false;
    }
    $.ajax({
      type: "get",
      url: '/plannings/' + planning_id + '/optimize.json',
      data: { 'global': $(this).data('opti-global') },
      beforeSend: beforeSendWaiting,
      success: function(data) {
        displayPlanning(data, {
          error: errorOptimize,
          success: successOptimize
        })
      },
      complete: completeAjaxMap,
      error: ajaxError
    });
  });

  var sortPlanning = function(event, ui) {
    var item = $(ui.item),
      index = 0,
      route = item.closest('[data-route_id]'),
      stops = $('.sortable li[data-stop_id]', route),
      route_id = route.attr('data-route_id'),
      stop_id = item.closest("[data-stop_id]").attr("data-stop_id");
    while (stops[index].attributes['data-stop_id'].value != stop_id) {
      index++;
    }
    $.ajax({
      type: 'patch',
      url: '/plannings/' + planning_id + '/' + route_id + '/' + stop_id + '/move/' + (index + 1) + '.json',
      beforeSend: beforeSendWaiting,
      success: updatePlanning,
      complete: completeAjaxMap,
      error: function(request, status, error) {
        ajaxError(request, status, error);
        $("#out_of_route, .stops").sortable('cancel');
      }
    });
  }

  var routeStepTrace = L.Polyline.extend({
    addDriveInfos: function(drive_time, distance) {
      this.on('mouseover', function(e) {
        var layer = e.target;
        layer.setStyle({
          opacity: 0.9,
          weight: 7
        });
      });
      this.on('mouseout', function(e) {
        var layer = e.target;
        layer.setStyle({
          opacity: 0.5,
          weight: 5
        });
        //this.closePopup(); // doesn't work with Firefox
      });
      var driveTime = (drive_time !== null) ? ('0' + parseInt(drive_time / 3600) % 24).slice(-2) + ':' + ('0' + parseInt(drive_time / 60) % 60).slice(-2) + ':' + ('0' + (drive_time % 60)).slice(-2) : '';
      this.bindPopup((driveTime ? '<div>' + I18n.t('plannings.edit.popup.stop_drive_time') + ' ' + driveTime + '</div>' : '') + '<div>' + I18n.t('plannings.edit.popup.stop_distance') + ' ' + distance.toFixed(1) + ' km</div>');
      return this;
    }
  });

  var prepareAndDisplayRouteOnMap = function(data, route) {
    var color = route.color || (route.vehicle && route.vehicle.color) || '#707070';
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
        var n = [],
          i;
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
        (new routeStepTrace(L.PolylineUtil.decode(stop.trace, 6), {
          color: color
        })).addDriveInfos(stop.drive_time, stop.distance).addTo(layers[route.route_id]);
        (new routeStepTrace(L.PolylineUtil.decode(stop.trace, 6), {
          offset: 3,
          color: color
        })).addDriveInfos(stop.drive_time, stop.distance).addTo(layers_cluster[route.route_id]);
      }
      if (stop.destination && $.isNumeric(stop.lat) && $.isNumeric(stop.lng)) {
        stop.i18n = mustache_i18n;
        stop.color = color;
        stop.vehicle_name = vehicle_name;
        stop.route_id = route.route_id;
        stop.capacity1_1_unit = route.capacity1_1_unit;
        stop.capacity1_2_unit = route.capacity1_2_unit;
        stop.routes = allRoutesVehicles;
        stop.planning_id = data.planning_id;
        stop.isoline_capability = params.isoline_capability.isochrone || params.isoline_capability.isodistance;
        stop.isochrone_capability = params.isoline_capability.isochrone;
        stop.isodistance_capability = params.isoline_capability.isodistance;
        var m = L.marker(new L.LatLng(stop.lat, stop.lng), {
          icon: new L.NumberedDivIcon({
            number: stop.number,
            iconUrl: '/images/' + (stop.destination.icon || 'point') + '-' + (stop.destination.color || color).substr(1) + '.svg',
            iconSize: new L.Point(12, 12),
            iconAnchor: new L.Point(6, 6),
            popupAnchor: new L.Point(0, -6),
            className: "small"
          })
        }).addTo(layers[route.route_id]).addTo(layers_cluster[route.route_id]).bindPopup(SMT['stops/show']({
          stop: stop
        }), {
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
            enlighten_stop(stop.stop_id);
          }
        }).on('popupopen', function(e) {
          $('.phone_number', e.popup._container).click(function(e) {
            phone_number_call(e.currentTarget.innerHTML, url_click2call, e.target);
          });
          $('[data-target$=isochrone-modal]').click(function(e) {
            $('#isochrone_lat').val(stop.lat);
            $('#isochrone_lng').val(stop.lng);
            $('#isochrone_vehicle_usage_id').val(route.vehicle_usage_id);
          });
          $('[data-target$=isodistance-modal]').click(function(e) {
            $('#isodistance_lat').val(stop.lat);
            $('#isodistance_lng').val(stop.lng);
            $('#isodistance_vehicle_usage_id').val(route.vehicle_usage_id);
          });
        }).on('popupclose', function(e) {
          m.click = false;
        });
        markers[stop.stop_id] = m;
      }
    });
    if (route.store_stop && route.store_stop.stop_trace) {
      (new routeStepTrace(L.PolylineUtil.decode(route.store_stop.stop_trace, 6), {
        color: color
      })).addDriveInfos(route.store_stop.stop_drive_time, route.store_stop.stop_distance).addTo(layers[route.route_id]);
      (new routeStepTrace(L.PolylineUtil.decode(route.store_stop.stop_trace, 6), {
        offset: 3,
        color: color
      })).addDriveInfos(route.store_stop.stop_drive_time, route.store_stop.stop_distance).addTo(layers_cluster[route.route_id]);
    }

    if (!route.hidden) {
      routes_layers_cluster.addLayer(layers_cluster[route.route_id]);
      routes_layers.addLayer(layers[route.route_id]);
    }
  }

  var initRoutes = function(context, data) {

    $.each($('.customer_external_callback_url'), function(i, element) {
      $(element).click(function(e) {
        $.ajax({
          url: $(e.target).data('url'),
          type: 'GET',
          beforeSend: function(jqXHR, settings) {
            beforeSendWaiting();
          },
          complete: function(jqXHR, textStatus) {
            completeWaiting();
          },
          success: function(data, textStatus, jqXHR) {
            notice(I18n.t('plannings.edit.export.customer_external_callback_url.success'));
          },
          error: function(jqXHR, textStatus, errorThrown) {
            stickyError(I18n.t('plannings.edit.export.customer_external_callback_url.fail'));
          }
        });
      });
    });

    /* API: Devices */
    devices_observe_planning(context);

    var templateSelectionColor = function(state) {
      if (state.id) {
        return $("<span class='color_small' style='background:" + state.id + "'></span>");
      } else {
        return $("<i />").addClass("fa fa-paint-brush").css("color", "#CCC");
      }
    }

    var templateResultColor = function(state) {
      if (state.id) {
        return $("<span class='color_small' style='background:" + state.id + "'></span>");
      } else {
        return $("<span class='color_small' data-color=''></span>");
      }
    }

    fake_select2($(".color_select", context), function(select) {
      select.select2({
        minimumResultsForSearch: -1,
        templateSelection: templateSelectionColor,
        templateResult: templateResultColor,
        formatNoMatches: I18n.t('web.select2.empty_result')
      }).select2("open");
      select.next('.select2-container--bootstrap').addClass('input-sm');
    });

    var templateSelectionVehicles = function(state) {
      if (state.id) {
        var color = $('.color_select', $(state.element).parent().parent()).val();
        if (color) {
          return $("<span/>").text(vehicles_usages_map[state.id].name);
        } else {
          return $("<span><span class='color_small' style='background:" + vehicles_usages_map[state.id].color + "'></span>&nbsp;</span>").append($("<span/>").text(vehicles_usages_map[state.id].name));
        }
      }
    }

    var templateResultVehicles = function(state) {
      if (state.id) {
        return $("<span><span class='color_small' style='background:" + vehicles_usages_map[state.id].color + "'></span>&nbsp;</span>").append($("<span/>").text(vehicles_usages_map[state.id].name));
      } else {
        console.log(state);
      }
    }

    fake_select2($(".vehicle_select", context), function(select) {
      select.select2({
        minimumResultsForSearch: -1,
        data: vehicles_array,
        templateSelection: templateSelectionVehicles,
        templateResult: templateResultVehicles,
        formatNoMatches: I18n.t('web.select2.empty_result')
      }).select2("open");
      select.next('.select2-container--bootstrap').addClass('input-sm');
    });

    $(".vehicle_select", context).change(function() {
      var $this = $(this);
      var initial_value = $this.data("initial-value");
      if (initial_value != $this.val()) {
        $.ajax({
          type: "patch",
          data: JSON.stringify({
            route_id: $this.closest("[data-route_id]").attr("data-route_id"),
            vehicle_usage_id: vehicles_usages_map[$this.val()].vehicle_usage_id
          }),
          contentType: 'application/json',
          url: '/plannings/' + planning_id + '/switch.json',
          beforeSend: beforeSendWaiting,
          success: function(data) {
            displayPlanning(data, {
              partial: 'routes'
            });
          },
          complete: completeAjaxMap,
          error: ajaxError
        });
      }
    });

    $('.export_spreadsheet').click(function() {
      $('[name=spreadsheet-route]').val($(this).closest("[data-route_id]").attr("data-route_id"));
      $('#planning-spreadsheet-modal').modal({
        keyboard: true,
        show: true
      });
    });

    // KMZ: Export Route via E-Mail
    $('.kmz_email a', context).click(function(e) {
      e.preventDefault();
      $.ajax({
        url: $(e.target).attr('href'),
        type: 'GET',
        beforeSend: function(jqXHR, settings) {
          beforeSendWaiting();
        },
        complete: function(jqXHR, textStatus) {
          completeWaiting();
        },
        success: function(data, textStatus, jqXHR) {
          notice(I18n.t('plannings.edit.export.kmz_email.success'));
        },
        error: function(jqXHR, textStatus, errorThrown) {
          stickyError(I18n.t('plannings.edit.export.kmz_email.fail'));
        }
      });
    });

    // iCalendar Export
    observe_icalendar_export();

    $(".routes", context).sortable({
      disabled: true,
      items: "li.route"
    });

    $(".routes", context)
      .on("click", ".toggle", function(event, ui) {
        var id = $(this).closest("[data-route_id]").attr("data-route_id");
        var li = $("ul.stops, ol.stops", $(this).closest("li"));
        li.toggle();
        var hidden = !li.is(":visible");
        $.ajax({
          type: "put",
          data: JSON.stringify({
            hidden: hidden
          }),
          contentType: 'application/json',
          url: '/api/0.1/plannings/' + planning_id + '/routes/' + id + '.json',
          error: ajaxError
        });

        var i = $("i", this);
        if (hidden) {
          i.removeClass("fa-eye").addClass("fa-eye-slash");
          routes_layers.removeLayer(layers[id]);
          routes_layers_cluster.removeLayer(layers_cluster[id]);
        } else {
          i.removeClass("fa-eye-slash").addClass("fa-eye");
          routes_layers.addLayer(layers[id]);
          routes_layers_cluster.addLayer(layers_cluster[id]);
        }
      })
      .on("click", ".marker", function(event, ui) {
        var stop_id = $(this).closest("[data-stop_id]").attr("data-stop_id");
        if (stop_id in markers) {
          map.setView(markers[stop_id].getLatLng(), 17, {
            reset: true
          });
          var route_id = $(this).closest("[data-route_id]").attr("data-route_id");
          layers_cluster[route_id].zoomToShowLayer(markers[stop_id], function() {
            markers[stop_id].openPopup();
          });
        } else {
          var store_id = $(this).closest("[data-store_id]").attr("data-store_id");
          if (store_id in stores) {
            map.setView(stores[store_id].getLatLng(), 17, {
              reset: true
            });
            stores[store_id].openPopup();
          }
        }
        $(this).blur();
        return false;
      })
      .on("click", ".optimize", function(event, ui) {

        initOptimizerDialog();

        if (!confirm(I18n.t('plannings.edit.optimize_confirm'))) {
          return;
        }
        var id = $(this).closest("[data-route_id]").attr("data-route_id");
        $.ajax({
          type: "get",
          url: '/plannings/' + planning_id + '/' + id + '/optimize.json',
          beforeSend: beforeSendWaiting,
          success: function(data) {
            updatePlanning(data, {
              error: errorOptimize,
              success: successOptimize
            });
          },
          complete: completeAjaxMap,
          error: ajaxError
        });
      })
      .on("click", ".active_all, .active_reverse, .active_none, .reverse_order", function(event, ui) {
        var url = this.href;
        $.ajax({
          type: "patch",
          url: url,
          beforeSend: beforeSendWaiting,
          success: updatePlanning,
          complete: completeAjaxMap,
          error: ajaxError
        });
        if ($(this).hasClass('reverse_order'))
          $(this).closest(".dropdown-menu").prev().dropdown("toggle");
        return false;
      })
      .on("change", "[name=route\\\[ref\\\]]", function() {
        var id = $(this).closest("[data-route_id]").attr("data-route_id");
        var ref = this.value;
        $.ajax({
          type: "put",
          data: JSON.stringify({
            ref: ref
          }),
          contentType: 'application/json',
          url: '/api/0.1/plannings/' + planning_id + '/routes/' + id + '.json',
          error: ajaxError
        });
      })
      .on("change", "[name=route\\\[color\\\]]", function() {
        var vehicle_select = $('.vehicle_select', $(this).closest("[data-route_id]"));
        vehicle_select.trigger('change');
        var id = $(this).closest("[data-route_id]").attr("data-route_id");
        var color = this.value;
        if (color)
          $('.color_small', $('.vehicle_select', $(this).parent()).next()).hide();
        else
          $('.color_small', $('.vehicle_select', $(this).parent()).next()).show();
        $.ajax({
          type: "put",
          data: JSON.stringify({
            color: color
          }),
          contentType: 'application/json',
          url: '/api/0.1/plannings/' + planning_id + '/routes/' + id + '.json',
          error: ajaxError
        });
        routes_array.forEach(function(route) {
          if (route.route_id == id)
            route.color = color;
        });
        var route = data.routes.reduce(function(found, el) {
          return found || (el.route_id == id && el);
        }, null);
        route.color = color;
        prepareAndDisplayRouteOnMap(data, route);
        $('li[data-route_id=' + id + '] .fa-home').css('color', color);
        $('li[data-route_id=' + id + '] li[data-stop_id] .number:not(.color_force)').css('background', color || route.vehicle.color);
        $('span[data-route_id=' + id + '] i.vehicle-icon').css('color', color || route.vehicle.color);
      });

    $(".lock").click(function(event, ui) {
      var id = $(this).closest("[data-route_id]").attr("data-route_id");
      var i = $("i", this);
      i.toggleClass("fa-lock");
      i.toggleClass("fa-unlock");
      $(this).toggleClass("btn-default");
      $(this).toggleClass("btn-warning");
      var locked = i.hasClass("fa-lock");
      $.ajax({
        type: "put",
        data: JSON.stringify({
          locked: locked
        }),
        contentType: 'application/json',
        url: '/api/0.1/plannings/' + planning_id + '/routes/' + id + '.json',
        error: ajaxError
      });
    });
  };

  var buildUrl = function(url, hash) {
    $.each(hash, function(k, v) { url = url.replace('\{' + k.toUpperCase() + '\}', hash[k]) });
    return url;
  }

  var displayPlanning = function(data, options) {

    if (!progressDialog(data.optimizer, dialog_optimizer, '/plannings/' + planning_id + '.json', displayPlanning, options && options.error, options && options.success)) {
      $('body').addClass('ajax_waiting');
      return;
    }

    function api_route_calendar_path(route) {
      return '/api/0.1/plannings/' + (planning_ref ? 'ref:' + encodeURIComponent(planning_ref) : planning_id) +
        '/routes/' + (route.ref ? 'ref:' + encodeURIComponent(route.ref) : route.route_id) + '.ics';
    }

    $.each(data.routes, function(i, route) {

      route.calendar_url = api_route_calendar_path(route)
      route.calendar_url_api_key = api_route_calendar_path(route) + '?api_key=' + user_api_key;

      if (route.vehicle_id) {
        route.vehicle = vehicles_usages_map[route.vehicle_id];
        route.path = '/vehicle_usages/' + route.vehicle_usage_id + '/edit?back=true';
      }

      route.customer_enable_external_callback = data.customer_enable_external_callback;
      if (data.customer_external_callback_url) {
        route.customer_external_callback_url = buildUrl(data.customer_external_callback_url, { planning_id: data.id, route_id: route.route_id, planning_ref: data.ref, route_ref: route.ref });
      }
    });

    if (data.customer_enable_external_callback && data.customer_external_callback_url) {
      $.each($('#global_tools').find('.customer_external_callback_url'), function(i, element) {
        $(element).data('url', buildUrl(data.customer_external_callback_url, { planning_id: data.id, planning_ref: data.ref }));
      });
    }

    data.i18n = mustache_i18n;
    data.planning_id = data.id;

    var empty_colors = colors.slice();
    empty_colors.unshift('');
    $.each(data.routes, function(i, route) {
      route.colors = $.map(empty_colors, function(color) {
        return {
          color: color,
          selected: route.color == color
        };
      });
      $.each(route.stops, function(i, stop) {
        if (stop.destination && stop.destination.color) {
          stop.destination.color_force = true;
        } else {
          stop.color = route.color;
        }
      });
    });

    $.each(data.routes, function(i, route) {
      prepareAndDisplayRouteOnMap(data, route);
    });

    if (typeof options !== 'object' || !options.partial) {
      data.ref = null; // here to prevent mustach template to get the value
      $("#planning").html(SMT['plannings/edit'](data));

      initRoutes($('#edit-planning'), data);

      $("#refresh").click(function(event, ui) {
        $.ajax({
          type: "get",
          url: '/plannings/' + planning_id + '/refresh.json',
          beforeSend: beforeSendWaiting,
          success: displayPlanning,
          complete: completeAjaxMap,
          error: ajaxError
        });
      });
    } else if (typeof options === 'object' && options.partial == 'routes') {
      // update allRoutesVehicles
      $.each(data.routes, function(i, route) {
        var vehicle_usage = {};
        $.each(vehicles_usages_map, function(i, v) {
          if (v.vehicle_usage_id == route.vehicle_usage_id) vehicle_usage = v;
        });
        $.each(allRoutesVehicles, function(i, rv) {
          if (rv.route_id == route.route_id)
            allRoutesVehicles[i] = {
              route_id: route.route_id,
              color: route.color || vehicle_usage.color,
              vehicle_usage_id: route.vehicle_usage_id,
              ref: route.ref,
              name: (route.ref ? (route.ref + ' ') : '') + vehicle_usage.name
            }
        });
      });

      $.each(data.routes, function(i, route) {
        route.i18n = mustache_i18n;
        route.planning_id = data.id;
        route.routes = allRoutesVehicles;

        $(".route[data-route_id='" + route.route_id + "']").html(SMT['routes/edit'](route));

        initRoutes($(".route[data-route_id='" + route.route_id + "']"), data);

        var regExp = new RegExp('/plannings/' + route.planning_id + '/' + route.route_id + '/[0-9]+/move.json');
        // popups are not selected follow
        $.each($('.send_to_route'), function(j, link) {
          $link = $(link);
          if ($link.attr('href').match(regExp) != null)
            $link.html('<div class="color_small" style="background:' + (route.color || route.vehicle.color) + '"></div> ' + route.vehicle.name);
        });
        // for popups outside DOM
        $.each(layers, function(route_id, layer) {
          $.each(layer.getLayers(), function(k, m) {
            if (m instanceof L.Marker) {
              var popupContent = $(m.getPopup().getContent());
              $.each($('.send_to_route', popupContent), function(j, link) {
                $link = $(link);
                if ($link.attr('href').match(regExp) != null)
                  $link.html('<div class="color_small" style="background:' + (route.color || route.vehicle.color) + '"></div> ' + route.vehicle.name);
              });
              m.getPopup().setContent(popupContent[0]);
            }
          });
        });
      });
    } else if (typeof options === 'object' && options.partial == 'stops') {
      $.each(data.routes, function(i, route) {
        route.i18n = mustache_i18n;
        route.planning_id = data.id;
        route.routes = allRoutesVehicles;

        $(".route[data-route_id='" + route.route_id + "'] .route-details").html(SMT['stops/list'](route));
      });

      $('.global_info').html(SMT['plannings/edit_head'](data));
    }

    $("#out_of_route .sortable").sortable({
      connectWith: ".sortable",
      update: sortPlanning
    }).disableSelection();

    $.each(data.routes, function(i, route) {
      var sortableUpdate = false;
      $(".route[data-route_id='" + route.route_id + "'] .stops.sortable").sortable({
        distance: 8,
        connectWith: ".sortable",
        items: "> li",
        cancel: '.wait',
        start: function(event, ui) {
          sortableUpdate = false;
        },
        update: function(event, ui) {
          sortableUpdate = true;
        },
        stop: function(event, ui) {
          if (sortableUpdate) {
            sortPlanning(event, ui);
          }
        }
      }).disableSelection();

      $(".route[data-route_id='" + route.route_id + "'] li[data-stop_id]")
      .mouseover(function() {
        $('span.number', this).css({
          display: 'none'
        });
        $('i.fa-reorder', this).css({
          display: 'inline-block'
        });
      })
      .mouseout(function() {
        var $this = $(this);
        $('i.fa-reorder', this).css({
          display: 'none'
        });
        $('span.number', this).css({
          display: 'inline-block'
        });
      })
      .each(function() {
        var $this = $(this);
        var stops = $.grep(route.stops, function(e) { return e.stop_id == $this.data('stop_id'); });
        if (stops.length > 0) {
          $this.popover({
            content: SMT['stops/show'](
              {
                stop: stops[0]
              }
            ),
            html: true,
            placement: 'auto',
            trigger: 'manual'
          });
        }
      })
      .click(function() {
        $("li[data-stop_id!='" + $(this).data('stop_id') + "']").popover('hide');
        $(this).popover($('.sidebar').hasClass('extended') ? 'toggle' : 'hide');
      });
    });
  }

  var updatePlanning = function(data, options) {
    displayPlanning(data, $.extend({
      partial: 'stops'
    }, options));
  }

  function automaticInsertStops(stop_ids, options) {
    $.ajax($.extend({
      url: '/plannings/' + planning_id + '/automatic_insert',
      type: 'PATCH',
      dataType: 'json',
      data: {
        stop_ids: stop_ids
      },
      beforeSend: beforeSendWaiting,
      complete: completeAjaxMap,
      error: ajaxError,
      success: updatePlanning
    }, options));
  }

  $(".main").on("click", ".automatic_insert", function(e, ui) {
    var stop_id = $(this).closest("[data-stop_id]").attr("data-stop_id");
    automaticInsertStops([stop_id], {
      success: function(data, textStatus, jqXHR) {
        updatePlanning(data);
        enlighten_stop(stop_id);
      }
    });
  });

  $(".main").on("click", ".automatic_insert_all", function(e, ui) {
    if ($('#out_of_route > li').length > 20) {
      alert(I18n.t('plannings.edit.automatic_insert_too_many'));
      return false;
    }
    if (confirm(I18n.t('plannings.edit.automatic_insert_confirm'))) {
      var dialog = bootstrap_dialog($.extend(modal_options(), {
        title: I18n.t('plannings.edit.dialog.automatic_insert.title'),
        message: SMT['modals/default_with_progress']({
          msg: I18n.t('plannings.edit.dialog.automatic_insert.in_progress')
        })
      })).modal({
        keyboard: false,
        show: true
      });
      automaticInsertStops([], {
        complete: function() {
          dialog.modal('hide');
          completeAjaxMap();
        }
      });
    }
  });

  $(".main").on('change', 'input:checkbox.stop_active', function(event, ui) {
    var route_id = $(event.target).closest("[data-route_id]").attr("data-route_id");
    var stop_id = $(event.target).closest("[data-stop_id]").attr("data-stop_id");
    var active = $(event.target).is(':checked');
    $.ajax({
      type: "patch",
      data: JSON.stringify({
        stop: {
          active: active
        }
      }),
      contentType: 'application/json',
      url: '/plannings/' + planning_id + '/' + route_id + '/' + stop_id + '.json',
      beforeSend: beforeSendWaiting,
      success: updatePlanning,
      complete: completeAjaxMap,
      error: ajaxError
    });
  });

  $(".main").on("click", ".send_to_route", function(event, ui) {
    var stop_id = $(this).closest("[data-stop_id]").attr("data-stop_id");
    var url = this.href;
    $.ajax({
      type: 'patch',
      url: url,
      beforeSend: beforeSendWaiting,
      success: function(data) {
        data.stop_id_enlighten = stop_id;
        updatePlanning(data);
      },
      complete: completeAjaxMap,
      error: ajaxError
    });
    return false;
  });

  var displayPlanningFirstTime = function(data) {
    displayPlanning(data);

    var stores_marker = L.featureGroup();
    stores = {};
    $.each(data.stores, function(i, store) {
      store.i18n = mustache_i18n;
      store.store = true;
      store.planning_id = data.planning_id;
      store.edit_planning = true;
      store.isoline_capability = params.isoline_capability.isochrone || params.isoline_capability.isodistance;
      store.isochrone_capability = params.isoline_capability.isochrone;
      store.isodistance_capability = params.isoline_capability.isodistance;
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
        }), {
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
        }).on('popupopen', function(e) {
          $('[data-target$=isochrone-modal]').click(function(e) {
            $('#isochrone_lat').val(store.lat);
            $('#isochrone_lng').val(store.lng);
            $('#isochrone_vehicle_usage_id').val('');
          });
          $('[data-target$=isodistance-modal]').click(function(e) {
            $('#isodistance_lat').val(store.lat);
            $('#isodistance_lng').val(store.lng);
            $('#isodistance_vehicle_usage_id').val('');
          });
        }).on('popupclose', function(e) {
          m.click = false;
        });
        stores[store.id] = m;
      }
    });
    stores_marker.addTo(map);

    if (fitBounds) {
      var bounds = routes_layers.getBounds();
      if (bounds && bounds.isValid()) {
        map.invalidateSize();
        map.fitBounds(bounds, {
          animate: false,
          padding: [20, 20]
        });
      }
    }
  }

  var checkForDisplayPlanningFirstTime = function(data) {
    if (data.out_of_date) {

      var displayPlanningAfterModal = function() {
        var cursorBody = $('body').css('cursor');
        var cursorMap = $('#map').css('cursor');
        $('body, #map').css({
          cursor: 'progress'
        });
        setTimeout(function() {
          displayPlanningFirstTime(data);
          $('body').css({
            cursor: cursorBody
          });
          $('#map').css({
            cursor: cursorMap
          });
        }, 100);
      }

      $('#planning-refresh-modal').modal({
        keyboard: true,
        show: true
      });
      $("#refresh-modal").click(function(event, ui) {
        $('#planning-refresh-modal').off('hidden.bs.modal', displayPlanningAfterModal);
        $('#planning-refresh-modal').modal('hide');
        $.ajax({
          type: "get",
          url: '/plannings/' + planning_id + '/refresh.json',
          beforeSend: beforeSendWaiting,
          success: displayPlanningFirstTime,
          complete: completeAjaxMap,
          error: ajaxError
        });
      });
      $('#planning-refresh-modal').on('hidden.bs.modal', displayPlanningAfterModal);
    } else {
      displayPlanningFirstTime(data);
    }
  }

  $('.btn.extend').click(function() {
    $('.sidebar').toggleClass('extended');
    if ($('.sidebar').hasClass('extended')) {
      $(".routes").sortable("enable");
    } else {
      $(".routes").sortable("disable");
    }
  });

  $.ajax({
    url: '/plannings/' + planning_id + '.json',
    beforeSend: beforeSendWaiting,
    success: checkForDisplayPlanningFirstTime,
    complete: completeAjaxMap,
    error: ajaxError
  });

  if (zoning_ids && zoning_ids.length > 0) {
    $.each(zoning_ids, function(i, zoningId) {
      $.ajax({
        type: "get",
        url: "/api/0.1/zonings/" + zoningId + ".json",
        beforeSend: beforeSendWaiting,
        success: displayZoning,
        complete: completeAjaxMap,
        error: ajaxError
      });
    });
  }

  $('#isochrone_size').timeEntry({
    show24Hours: true,
    spinnerImage: ''
  });

  $('#isochrone').click(function() {
    var vehicle_usage_id = $('#isochrone_vehicle_usage_id').val();
    var size = $('#isochrone_size').val().split(':');
    size = parseInt(size[0]) * 3600 + parseInt(size[1]) * 60;

    $.ajax({
      url: '/api/0.1/zonings/isochrone',
      type: "patch",
      dataType: "json",
      data: {
        vehicle_usage_id: vehicle_usage_id,
        size: size,
        lat: $('#isochrone_lat').val(),
        lng: $('#isochrone_lng').val()
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
    var vehicle_usage_id = $('#isodistance_vehicle_usage_id').val();
    var size = $('#isodistance_size').val() * 1000;
    $('#isodistance-progress-modal').modal({
      backdrop: 'static',
      keyboard: true
    });
    $('#isodistance-modal').modal('hide');
    $.ajax({
      type: "patch",
      url: '/api/0.1/zonings/isodistance.json',
      dataType: "json",
      data: {
        vehicle_usage_id: vehicle_usage_id,
        size: size,
        lat: $('#isodistance_lat').val(),
        lng: $('#isodistance_lng').val()
      },
      beforeSend: beforeSendWaiting,
      success: displayZoning,
      complete: function() {
        completeAjaxMap();
        $('#isodistance-progress-modal').modal('hide');
      },
      error: ajaxError
    });
  });

  // Export spreadsheet modal
  $('#planning-spreadsheet-modal').on('show.bs.modal', function() {
    if ($('[name=spreadsheet-route]').val())
      $('[name=spreadsheet-out-of-route]').parent().parent().hide();
    else
      $('[name=spreadsheet-out-of-route]').parent().parent().show();
  });
  if (localStorage.spreadsheetStops) {
    $.each($('.spreadsheet-stops'), function(i, cb) {
      $(cb).prop('checked', localStorage.spreadsheetStops.split('|').indexOf($(cb).val()) >= 0);
    });
  }
  $('.columns-export-list').sortable({
    connectWith: '#spreadsheet-columns .ui-sortable'
  });
  var columns_export = params.spreadsheet_columns;
  var columns_skip = localStorage.spreadsheetColumnsSkip && localStorage.spreadsheetColumnsSkip.split('|');
  if (localStorage.spreadsheetColumnsExport) {
    columns_export = localStorage.spreadsheetColumnsExport.split('|');
    $.each(params.spreadsheet_columns, function(i, c) {
      if (columns_export.indexOf(c) < 0 && (!columns_skip || columns_skip.indexOf(c) < 0))
        columns_export.push(c);
    });
  }
  $.each(columns_export, function(i, c) {
    if (params.spreadsheet_columns.indexOf(c) >= 0) {
      $('#columns-export').append('<li data-value="' + c + '">' + I18n.t('plannings.export_file.' + c) + ' <a class="remove"><i class="fa fa-close fa-fw"></i></a></li>');
    }
  });
  $.each(columns_skip, function(i, c) {
    if (params.spreadsheet_columns.indexOf(c) >= 0)
      $('#columns-skip').append('<li data-value="' + c + '">' + I18n.t('plannings.export_file.' + c) + ' <a class="remove"><i class="fa fa-close fa-fw"></i></a></li>');
  });
  $('#columns-export a.remove').click(function(evt) {
    var $elem = $(evt.currentTarget).closest('li');
    if ($elem.parent()[0].id == 'columns-export') {
      var nextFocus = $elem.next();
      $('a.remove', $elem).hide();
      $('#columns-skip').append($elem);
      if (nextFocus.length) $('a.remove', nextFocus).show();
    }
  });
  $('#columns-export li').mouseenter(function(evt) {
    if ($(evt.currentTarget).closest('#columns-export').length > 0)
      $('a.remove', evt.currentTarget).show();
  }).mouseleave(function(evt) {
    $('a.remove', evt.currentTarget).hide();
  });
  if (localStorage.spreadsheetFormat)
    $('[name=spreadsheet-format][value=' + localStorage.spreadsheetFormat + ']').prop('checked', true);

  $('#btn-spreadsheet').click(function() {
    var spreadsheetStops = localStorage.spreadsheetStops = $('.spreadsheet-stops:checked').map(function(i, e) {
      return $(e).val()
    }).get().join('|');
    var spreadsheetColumnsExport = localStorage.spreadsheetColumnsExport = $('#columns-export li').map(function(i, e) {
      return $(e).attr('data-value')
    }).get().join('|');
    var spreadsheetColumnsSkip = localStorage.spreadsheetColumnsSkip = $('#columns-skip li').map(function(i, e) {
      return $(e).attr('data-value')
    }).get().join('|');
    var spreadsheetFormat = localStorage.spreadsheetFormat = $('[name=spreadsheet-format]:checked').val();
    var basePath = $('[name=spreadsheet-route]').val() ? ('/routes/' + $('[name=spreadsheet-route]').val()) : ('/plannings/' + planning_id);
    window.location.href = basePath + '.' + spreadsheetFormat + '?stops=' + spreadsheetStops + '&columns=' + spreadsheetColumnsExport;
  });

  $('.export_spreadsheet').click(function() {
    $('#planning-spreadsheet-modal').modal({
      keyboard: true,
      show: true
    });
  });
};

var plannings_show = function(params) {
  if (!params.print_map) {
    window.print();
  } else {
    $('.btn-print').click(function() {
      window.print();
    });
  }
};

var observe_icalendar_export = function() {
  var url = $('#ical_export').attr('href'), ids;
  $('#ical-hook').click(function(){ 
    ids = $.makeArray($('input[type=checkbox]:checked').map(function(index, id){ return $(id).val(); }));
    $('#ical_export').attr('href', url + '&ids=' + ids.join(',') + '&email=false');
  });
  $('.icalendar_email').click(function(e) {
    e.preventDefault();
    $.ajax({
      url: $(e.target).attr('href'),
      type: 'GET',
      data: {
        ids: ids && ids.join(','),
        email: true
      },
    })
    .done(function(data) {
      notice(I18n.t('plannings.edit.export.icalendar.success'));
    })
    .fail(function() {
      stickyError(I18n.t('plannings.edit.export.icalendar.fail'));
    });
  });
};

var plannings_index = function(params) {
  observe_icalendar_export();
};

Paloma.controller('Plannings', {
  index: function() {
    plannings_index(this.params);
  },
  new: function() {
    plannings_new(this.params);
  },
  create: function() {
    plannings_new(this.params);
  },
  edit: function() {
    plannings_edit(this.params);
  },
  update: function() {
    plannings_edit(this.params);
  },
  show: function() {
    plannings_show(this.params);
  }
});
