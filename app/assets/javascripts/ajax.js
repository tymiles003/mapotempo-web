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

function beforeSendWaiting() {
  if (ajaxWaitingGlobal == 0) {
    $('body').addClass('waiting');
  }
  ajaxWaitingGlobal++;
}

function completeWaiting() {
  ajaxWaitingGlobal--;
  if (ajaxWaitingGlobal == 0) {
    $('body').removeClass('waiting');
  }
}

function ajaxError(request, status, error) {
  var otext = request.responseText;
  var text;
  try {
    text = "";
    $.each($.parseJSON(otext), function(i, e) {
      text += e;
    });
  } catch (e) {
    text = otext;
  }
  if (!text) {
    text = status;
  }
  $(".main .flash").prepend(
    '<div class="alert fade in alert-danger">' +
    '<button class="close" data-dismiss="alert">×</button>' +
    $('<div/>').text(text).html() +
    '</div>');
}

function mustache_i18n() {
  return function(text) {
    return I18n.t(text);
  }
}

function progress_dialog(data, dialog, callback, load_url, stop_url) {
  if (typeof data != 'undefined') {
    dialog.dialog("open");
    $(".progress-bar", dialog).css("width", "" + data.progress + "%");
    if (data.attempts) {
      $(".dialog-attempts-number", dialog).html(data.attempts);
      $(".dialog-attempts", dialog).show();
    } else {
      $(".dialog-attempts", dialog).hide();
    }
    if (data.error) {
      $(".dialog-progress", dialog).hide();
      $(".dialog-error", dialog).show();
      var buttons = {};
      buttons[I18n.t('web.dialog.close')] = function() {
        $.ajax({
          type: "delete",
          url: stop_url,
          beforeSend: beforeSendWaiting,
          complete: function() {
            dialog.dialog("close");
            completeWaiting();
            $.ajax({
              url: load_url,
              success: callback,
              error: ajaxError
            });
            // Reset dialog content
            $(".dialog-progress", dialog).show();
            $(".dialog-attempts", dialog).hide();
            $(".dialog-error", dialog).hide();
            $(".progress-bar", dialog).css("width", "0%");
            dialog.dialog({
              buttons: {}
            });
          },
          error: function(request, status, error) {
            ajaxError(request, status, error);
          }
        });
      }
      dialog.dialog({
        buttons: buttons
      });
    } else {
      setTimeout(function() {
        $.ajax({
          url: load_url,
          success: callback,
          error: ajaxError
        });
      }, 2000);
    }
    return false;
  } else {
    dialog.dialog("close");
  }
  return true;
}
