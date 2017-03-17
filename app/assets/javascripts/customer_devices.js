var devicesObserveCustomer = (function() {
  var _hash = {};

  function _devicesInitCustomer(base_name, config, params) {
    var requests = [];

    function clearCallback() {
      $('.' + config.name + '-api-sync').attr('disabled', 'disabled');
      $('#' + config.name + '_container').removeClass('panel-success panel-danger').addClass('panel-default');
    }

    function successCallback() {
      $('.' + config.name + '-api-sync').removeAttr('disabled');
      $('#' + config.name + '_container').removeClass('panel-default panel-danger').addClass('panel-success');
    }

    // maybe need rework on this one - WARNING -
    function errorCallback(apiError) {
      stickyError(apiError);
      $('.' + config.name + '-api-sync').attr('disabled', 'disabled');
      $('#' + config.name + '_container').removeClass('panel-default panel-success').addClass('panel-danger');
    }

    function _userCredential() {
      hash = _hash[config.name] = {};
      hash.customer_id = params.customer_id;
      // Used to make sure that password is not the same as the one generated rodomly | maybe change strategy on this
      $.each(config.forms.admin_customer, function(i, v) {
        hash[v[1]] = $('#' + base_name + "_" + config.name + "_" + v[1]).val() ||  void(0);
        if (v[1] == "password" && hash[v[1]] == params.default_password)
          hash[v[1]] = void(0);
      });
      return hash;
    }

    function _allFieldsFilled() {
      isNotEmpty = true;
      var inputs = $('input[type="text"], input[type="password"]', "#" + config.name + "_container");
      inputs.each(function() {
        if ($(this).val() == "")
          return isNotEmpty = false;
      });
      return isNotEmpty;
    }

    function _ajaxCall(all) {
      $.when($(requests)).done(function() {
        requests.push($.ajax({
          url: '/api/0.1/devices/' + config.name + '/auth.json',
          data: (all) ? _userCredential() : $.extend(_userCredential(), {
            check_only: 1
          }),
          dataType: 'json',
          beforeSend: function(jqXHR, settings) {
            if (!all) hideNotices();
            beforeSendWaiting();
          },
          complete: function(jqXHR, textStatus) {
            completeWaiting();
          },
          success: function(data, textStatus, jqXHR) {
            (data && data.error) ? errorCallback(data.error): successCallback();
          },
          error: function(jqXHR, textStatus, error) {
            errorCallback(textStatus);
          }
        }));
      });
    }

    // Check Credentials Without Before / Complete Callbacks ----- TRANSLATE IN ERROR CALL ISN'T SET 
    function checkCredentials() {
      if (!_allFieldsFilled()) return;
      _ajaxCall(true);
    }

      // Check Credentials: Observe User Events with Delay
    var _observe = function() {
      var timeout_id;

      // Anonymous function handle setTimeout()
      var check_credentials_with_delay = function() {
        if (timeout_id) clearTimeout(timeout_id);
        timeout_id = setTimeout(function () { _ajaxCall(false); }, 750);
      }

      $("#" + config.name + "_container input").on('keyup', function(e) {
        clearCallback();
        if (_allFieldsFilled())
          check_credentials_with_delay();
      });

      // Sync
      $('.' + config.name + '-api-sync').on('click', function(e) {
        if (confirm(I18n.t('customers.form.sync.' + config.name + '.confirm'))) {
          $.ajax({
            url: '/api/0.1/devices/' + config.name + '/sync.json',
            type: 'POST',
            data: $.extend(_userCredential(), {
              customer_id: params.customer_id
            }),
            beforeSend: function(jqXHR, settings) {
              beforeSendWaiting();
            },
            complete: function(jqXHR, textStatus) {
              completeWaiting();
            },
            success: function(data, textStatus, jqXHR) {
              alert(I18n.t('customers.form.sync.complete'));
            }
          });
        }
      });
    }

    /* Password Inputs: set fake password  (input view fake) */
    if ("password" in config) {
      var password_field = '#' + [base_name, config.name, "password"].join('_');
      if ($(password_field).val() == '') {
        $(password_field).val(params.default_password);
      }
    };

    // Check credantial for current device config
    // Observe Widget if Customer has Service Enabled or Admin (New Customer)
    checkCredentials();
    _observe();
  }

    /* Chrome / FF, Prevent Sending Default Password
       The browsers would ask to remember it. */
  (function() {
    $('form.clear-passwords').on('submit', function(e) {
      $.each($(e.target).find('input[type=\'password\']'), function(i, element) {
        if ($(element).val() == params.default_password) {
          $(element).val('');
        }
      });
      return true;
    });
  })();

  var initialize = function(params) {
    $.each(params['devices'], function(deviceName, config) {
      config.name = deviceName;
      _devicesInitCustomer('customer_devices', config, params);
    });
  }

  return { init: initialize };
})();
