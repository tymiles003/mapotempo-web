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
/*
jQuery(function() {
  $("a[rel~=popover], .has-popover").popover();
  $("a[rel~=tooltip], .has-tooltip").tooltip();
});
*/

var bootstrap_alert = function(status, message, timeout) {
  $('.flash').append('<div class="alert fade in alert-' + status + '"><button class="close" data-dismiss="alert">×</button>' + message + '</div>');

  if (timeout || timeout === 0) {
    hideAlert('.alert', timeout);
  }
};

var bootstrap_alert_success = function(message, timeout) {
  bootstrap_alert('success', message, timeout);
};

var bootstrap_alert_danger = function(message, timeout) {
  bootstrap_alert('danger', message, timeout);
};

var timeAlert = 5000;
var hideAlert = function(elem, timeout) {
  var $elem = $(elem);
  if ($elem.length > 0) {
    var delta = timeout/10,
      tid;
    tid = setInterval(function() {
      if (window.blurred) { return; }
      timeout -= delta;
      if (timeout <= 0) {
        clearInterval(tid);
        $elem.alert('close');
      }
    }, delta);
  }
}

window.onblur = function() { window.blurred = true; };
window.onfocus = function() { window.blurred = false; };
