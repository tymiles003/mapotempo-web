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
function customers_edit(params) {
  $('#customer_end_subscription').datepicker({
    language: defaultLocale,
    autoclose: true,
    todayHighlight: true
  });

  $('#customer_take_over').timeEntry({
    show24Hours: true,
    showSeconds: true,
    initialField: 1,
    defaultTime: new Date(0, 0, 0, 0, 0, 0),
    spinnerImage: ''
  });

  $('#accordion').on('show.bs.collapse', function(event, ui) {
    $.fn.wysihtml5.locale['fr'] = $.fn.wysihtml5.locale['fr-FR'];
    // .wysihtml5 not working on hidden textarea
    $('#customer_print_header').wysihtml5({
      toolbar: {
        link: false,
        image: false,
        blockquote: false,
        size: 'sm',
        fa: true
      },
      locale: defaultLocale
    });
  });
}

Paloma.controller('Customer').prototype.new = function() {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.create = function() {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.edit = function() {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.update = function() {
  customers_edit(this.params);
};
