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

var progress_attempt = undefined;
var progress_dialog = function(data, dialog, load_url, callback, error_callback, success_callback) {
  if (data !== undefined) {
    var timeout;
    dialog.modal(modal_options());
    var progress = data.progress && data.progress.split(';');
    $(".progress-bar", dialog).each(function(i, e) {
      if (progress == undefined || progress == '' || progress[i] == undefined || progress[i] == '') {
        $(e).parent().parent().hide();
      } else {
        $(e).parent().parent().show();
      }
      if (!progress || !progress[i]) {
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 0s");
        $(e).css("width", "0%");
      } else if (progress[i] == 100) {
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 0s");
        $(e).css("width", "100%");
      } else if (progress[i] == -1) {
        $(e).parent().addClass("active");
        $(e).css("transition", "linear 0s");
        $(e).css("width", "100%");
      } else if (progress[i].indexOf('ms') > -1) {
        if (progress_attempt != data.attempts) {
          var v = progress[i].split('ms');
          var iteration = $(e).data('iteration');
          if (iteration != v[1]) {
            $(e).data('iteration', iteration);
            $(e).css("transition", "linear 0s");
            $(e).css("width", "0%");
          }
          if (parseInt($(e).css("width")) == 0) {
            timeout = parseInt(v[0]);
            $(e).parent().removeClass("active");
            $(e).css("transition", "linear " + (timeout / 1000) + "s");
            $(e).css("width", "100%");
          }
        }
        progress_attempt = data.attempts;
      } else if (progress[i].indexOf('/') > -1) {
        var v = progress[i].split('/');
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 0.5s");
        $(e).css("width", "" + (100 * v[0] / v[1]) + "%");
        $(e).html(progress[i]);
      } else {
        $(e).parent().removeClass("active");
        $(e).css("transition", "linear 2s");
        $(e).css("width", "" + progress[i] + "%");
      }
    });
    if (data.attempts) {
      $(".dialog-attempts-number", dialog).html(data.attempts);
      $(".dialog-attempts", dialog).show();
    } else {
      $(".dialog-attempts", dialog).hide();
    }
    if (data.error) {
      if (error_callback) error_callback();
      $(".dialog-progress", dialog).hide();
      $(".dialog-error", dialog).show();
    } else {
      planningTimerId = setTimeout(function() {
        $.ajax({
          url: load_url,
          success: callback,
          error: ajaxError
        });
      }, 2000);
      $(document).on('page:before-change', function(e) {
        clearTimeout(planningTimerId);
        $(document).off('page:before-change');
      });
    }
    return false;
  } else {
    if (dialog.is(':visible')) {
      if (success_callback) success_callback();
      dialog.modal('hide');
      $($(".progress-bar", dialog)).css("width", "0%");
    }
    progress_attempt = undefined;
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
