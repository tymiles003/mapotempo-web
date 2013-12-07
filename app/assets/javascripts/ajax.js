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
