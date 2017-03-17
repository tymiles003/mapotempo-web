var devicesObserveVehicle = (function() {
  const base_name = 'vehicle_usage_vehicle_devices';

  var _buildSelect = function(data, name, devices) {
    $('[data-device=' + name + ']').select2({
      data: data,
      theme: 'bootstrap',
      width: '100%',
      // placeholder: I18n.t('vehicle_usages.form.devices.placeholder'),
      minimumResultsForSearch: -1,
      templateResult: function(data_selection) {
        return data_selection.text;
      },
      templateSelection: function(data_selection) {
        return data_selection.text;
      }
    });
    // this is used to set a default value for select2 builder
    $('[data-device=' + name + ']').val(devices[name + "_id"] || data[0]).trigger("change");
  }

  var _devicesInitVehicle = function(name, params) {
    $.ajax({
      url: '/api/0.1/devices/' + name + '/devices.json',
      data: {
        customer_id: params.customer_id
      },
      dataType: 'json',
      success: function(data, textStatus, jqXHR) {
        // Blank option
        if (data && data.error) stickyError(data.error);
        _buildSelect(data, name, params.devices);
      },
      error: function(jqXHR, textStatus, errorThrown) {
        _buildSelect([errorThrown], name, params.devices);
      }
    });
  }

  var init = function(params) {
    $.each($("[data-device]"), function(i, deviceSelect) {
      _devicesInitVehicle($(deviceSelect).data('device'), params);
    });
  }

  return { init: init };
})();
