// Copyright © Mapotempo, 2013-2014
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
var ajaxWaitingGlobal = 0;
var planningTimerId;

var beforeSendWaiting = function() {
  if (ajaxWaitingGlobal == 0) {
    $('body').addClass('ajax_waiting');
  }
  ajaxWaitingGlobal++;
}

var completeWaiting = function() {
  ajaxWaitingGlobal--;
  if (ajaxWaitingGlobal == 0) {
    $('body').removeClass('ajax_waiting');
  }
}

var completeAjaxMap = function() {
  completeWaiting();
}

var ajaxError = function(request, status, error) {
  var otext = request.responseText;
  var text;
  try {
    text = "";
    $.each($.parseJSON(otext), function(i, e) {
      text += " " + e;
    });
  } catch (e) {
    text = otext;
  }
  if (!text) {
    text = status;
  }
  if (request.readyState != 0)
    stickyError(text);
}

var mustache_i18n = function() {
  return function(text) {
    return I18n.t(text);
  };
}

var freezeProgressDialog = function(dialog) {
  dialog.find('[data-dismiss]').hide();
  dialog.off('hidden.bs.modal'); // important to avoid canceling old jobs
  dialog.off('keyup');
};

var unfreezeProgressDialog = function(dialog, delayedJob, url, callback) {
  dialog.find('[data-dismiss]').show();
  dialog.data()['bs.modal'].options.backdrop = false;
  dialog.on('hidden.bs.modal', function() {
    // delayedJob could contain neither customer_id nor id in case of server error...
    $.ajax({
      type: 'DELETE',
      url: '/api/0.1/customers/' + delayedJob.customer_id + '/job/' + delayedJob.id + '.json',
      success: function() {
        $.ajax({
          type: 'GET',
          url: url,
          beforeSend: beforeSendWaiting,
          success: callback,
          complete: completeAjaxMap,
          error: ajaxError
        });
      },
      error: ajaxError
    });
    dialog.off('keyup');
    // Reset dialog content
    $(".dialog-progress", dialog).show();
    $(".dialog-attempts", dialog).hide();
    $(".dialog-error", dialog).hide();
    $(".progress-bar", dialog).css("width", "0%");
  });
  dialog.on('keyup', function(e) {
    if (e.keyCode == 27) {
      dialog.modal('hide');
    }
    if (e.keyCode == 13) {
      dialog.find('.btn-primary')[0].click();
    }
  });
};

var iteration = undefined;
var progressDialog = function(delayedJob, dialog, url, callback, errorCallback, successCallback) {
  if (delayedJob !== undefined) {
    var timeout = 2000;
    var duration;
    dialog.modal(modal_options());
    freezeProgressDialog(dialog);
    var progress = delayedJob.progress && delayedJob.progress.split(';');
    $(".progress-bar", dialog).each(function(i, e) {
      if (progress == undefined || progress == '' || progress[i] == undefined || progress[i] == '') {
        $(e).parent().parent().hide();
      }
      else {
        $(e).parent().parent().show();
      }
      if (!progress || !progress[i]) {
        $(e).parent().removeClass("active");
        $(e).css({transition: 'linear 0s', width: '0%'});
      }
      else if (progress[i] == 100) {
        $(e).parent().removeClass("active");
        $(e).css({transition: 'linear 0s', width: '100%'});
      }
      else if (progress[i] == -1) {
        $(e).parent().addClass("active");
        $(e).css({transition: 'linear 0s', width: '100%'});
      }
      else if (progress[i].indexOf('ms') > -1) {
        // optimization in ms
        var v = progress[i].split('ms');
        if (iteration != v[1] || $(".dialog-attempts-number", dialog).html() != delayedJob.attempts) {
          iteration = v[1];
          $(e).css('transition', 'linear 0s');
          $(e).css('width', '0%');
          setTimeout(function() { // to be sure width is 0%
            duration = parseInt(v[0]);
            if (duration > timeout) {
              $(e).parent().removeClass("active");
              $(e).css("transition", "linear " + ((duration - timeout - 20) / 1000) + "s");
              $(e).css("width", "100%");
            }
          }, 20);
        }
      }
      else if (progress[i].indexOf('/') > -1) {
        // optimization or geocoding current/total
        var v = progress[i].split('/');
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 0.5s");
        $(e).css("width", "" + (100 * v[0] / v[1]) + "%");
        $(e).html(progress[i]);
      }
      else {
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 2s");
        $(e).css("width", "" + progress[i] + "%");
      }
    });
    if (delayedJob.attempts) {
      $(".dialog-attempts-number", dialog).html(delayedJob.attempts);
      $(".dialog-attempts", dialog).show();
    }
    else {
      $(".dialog-attempts", dialog).hide();
    }
    if (delayedJob.error) {
      if (errorCallback) errorCallback();
      $(".dialog-progress", dialog).hide();
      $(".dialog-error", dialog).show();
      unfreezeProgressDialog(dialog, delayedJob, url, callback);
    }
    else {
      planningTimerId = setTimeout(function() {
        $.ajax({
          url: url,
          success: function(data) {
            callback(data, {
              error: errorCallback,
              success: successCallback
            });
          },
          error: ajaxError
        });
      }, 2000);
      $(document).on('page:before-change', function(e) {
        clearTimeout(planningTimerId);
        $(document).off('page:before-change');
      });
    }
    return false;
  }
  else {
    if (dialog.is(':visible')) {
      if (successCallback) successCallback();
      dialog.modal('hide');
      $($(".progress-bar", dialog)).css("width", "0%");
    }
    return true;
  }
}


var fake_select2 = function(selector, callback) {
  var fake_select2_replace = function(fake_select) {
    var select = fake_select.prev();
    fake_select.hide();
    select.show();
    callback(select);
    fake_select.off();
  }

  var fake_select2_click = function(e) {
    // On the first click on select2-look like div, initialize select2, remove the placeholder and resend the click
    var fake_select = $(this);
    e.stopPropagation();
    fake_select2_replace(fake_select);
    if (e.clientX && e.clientY) {
      $(document.elementFromPoint(e.clientX, e.clientY)).click();
    }
  }

  var fake_select2_key_event = function(e) {
    var fake_select = $(this).closest('.fake');
    e.stopPropagation();
    var parent = $(this).parent();
    fake_select2_replace(fake_select);
    var input = $('input', parent);
    input.focus();
    // var ee = jQuery.Event('keydown');
    // ee.which = e.which;
    // $('input', $(this)).trigger(ee);
  }

  selector.next()
    .on('click', fake_select2_click)
    .on('keydown', fake_select2_key_event);
}

var phone_number_call = function(num, url_template, link) {
    if(num){
        link.href = url_template.replace('{TEL}', num);
        if(document.location.protocol == 'http:' && !(link.href.substr(0,5) == 'https')){
            link.target = link.target.replace('click2call_iframe', '_blank');
        }
    }
}
