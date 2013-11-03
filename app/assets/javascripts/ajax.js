var ajaxWaitingGlobal = 0;

function beforeSendWaiting() {
  if(ajaxWaitingGlobal == 0) {
    $('body').addClass('waiting');
  }
  ajaxWaitingGlobal++;
}

function completeWaiting() {
  ajaxWaitingGlobal--;
  if(ajaxWaitingGlobal == 0) {
    $('body').removeClass('waiting');
  }
}

function ajaxError(request, status, error) {
console.log(request);
console.log(status);
console.log(error);
  $(".main").prepend(
    '<div class="alert fade in alert-error">' +
    '<button class="close" data-dismiss="alert">×</button>' +
    status + ' ' + request.responseText +
   '</div>');
}
