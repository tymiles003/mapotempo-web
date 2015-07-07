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

function bootstrap_alert(status, message, timeout) {
  $('.flash').append('<div class="alert fade in alert-' + status + '"><button class="close" data-dismiss="alert">×</button>' + message + '</div>');

  if (timeout || timeout === 0) {
    hide_alert('.alert', timeout);
  }
};

function bootstrap_alert_success(message, timeout) {
  bootstrap_alert('success', message, timeout);
};

function bootstrap_alert_danger(message, timeout) {
  bootstrap_alert('danger', message, timeout);
};

function hide_alert(elem, timeout) {
  setTimeout(function() { 
    $(elem).alert('close');
  }, timeout);
}
