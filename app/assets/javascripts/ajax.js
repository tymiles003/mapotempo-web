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
  $(".main").prepend(
    '<div class="alert fade in alert-error">' +
    '<button class="close" data-dismiss="alert">×</button>' +
    status + ' ' + $('<div/>').text(request.responseText).html() +
    '</div>');
}

function mustache_i18n() {
  return function (text) {
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
    }
    if (data.error) {
      $(".dialog-progress", dialog).hide();
      $(".dialog-error", dialog).show();
      var buttons = {};
      buttons[I18n.t('web.dialog.close')] = function () {
        $.ajax({
          type: "delete",
          url: stop_url,
          beforeSend: beforeSendWaiting,
          complete: function () {
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
          error: function (request, status, error) {
            ajaxError(request, status, error);
          }
        });
      }
      dialog.dialog({
        buttons: buttons
      });
    } else {
      setTimeout(function () {
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
