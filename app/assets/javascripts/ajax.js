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
