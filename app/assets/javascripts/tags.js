// Copyright © Mapotempo, 2013-2017
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
'use strict';

// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var tags_form = function() {
  'use strict';

  $('#tag_color').simplecolorpicker({
    theme: 'fontawesome'
  });

  customColorInitialize('#tag_color');

  //for turbolinks, when clicking on link_to
  $('.selectpicker').selectpicker();
};

Paloma.controller('Tags', {
  new: function() {
    tags_form();
  },
  create: function() {
    tags_form();
  },
  edit: function() {
    tags_form();
  },
  update: function() {
    tags_form();
  }
});

var templateTag = function(item) {
  var color = $(item.element).attr('data-color');
  var icon = $(item.element).attr('data-icon');

  if (icon && color) {
    return $('<span><i style="color:#' + color + '" class="fa ' + icon + '"></i>&nbsp;</span>').append($("<span/>").text(item.text));
  } else if (icon) {
    return $('<span><i class="fa ' + icon + '"></i>&nbsp;</span>').append($("<span/>").text(item.text));
  } else if (color) {
    return $('<span><i style="color:#' + color + '" class="fa fa-flag"></i>&nbsp;</span>').append($("<span/>").text(item.text));
  } else {
    return item.text;
  }
};
