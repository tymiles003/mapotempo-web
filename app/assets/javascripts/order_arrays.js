// Copyright © Mapotempo, 2014
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
function order_arrays_form() {
  $('#order_array_base_date').datepicker({
    language: defaultLocale,
    autoclose: true,
    calendarWeeks: true,
    todayHighlight: true
  });
}

function order_arrays_new(params) {
  order_arrays_form();
}

function order_arrays_edit(params) {
  var order_array_id = params.order_array_id,
    block_save_select_change = false,
    table_neeed_update = false;

  function filter_text(exactText, normalizedValue, filter, index) {
    return !!String(normalizedValue).match(new RegExp(filter, 'i'));
  }

  var arrows = {
    "Right": [1, 0],
    "Left": [-1, 0],
    "Up": [0, -1],
    "Down": [0, 1]
  }

  function arrow_move_focus(td, e) {
    if (e.type == "keydown" && (e.key == "Right" || e.key == "Left" || e.key == "Up" || e.key == "Down")) {
      var tr = $(td).parent();
      var target = $('#order_array table tbody tr:nth-child(' + (tr.index() + arrows[e.key][1] + 1) + ') td:nth-child(' + (td.index() + arrows[e.key][0] + 1) + ')');
      target.focus();
      e.preventDefault();
      return true;
    }
  }

  var formatNoMatches = I18n.t('web.select2.empty_result');

  function replace_fake_select2(fake) {
    // On the first click on select2-look like div, initialize select2, remove the placeholder and resend the click
    fake.hide();
    var select = $('select[name$=\\[product_ids\\]\\[\\]]', fake.parent());
    select.show();
    select.select2({
      formatNoMatches: function() {
        return formatNoMatches;
      },
      width: '100%'
    });

    select.change(function(e) {
      if (block_save_select_change) {
        return;
      }

      table_neeed_update = true;
      build_total(undefined, $('#order_array table'));

      var id = select.parent().data('id');
      var product_ids = e.val;
      $.ajax({
        type: "put",
        data: {
          product_ids: product_ids
        },
        url: '/api/0.1/order_arrays/' + order_array_id + '/orders/' + id + '.json',
        beforeSend: beforeSendWaiting,
        complete: completeWaiting,
        error: ajaxError
      });
    });
    fake.remove();
  }

  function fake_select2_key_event(e) {
    e.stopPropagation();

    if (arrow_move_focus($(this), e)) {
      $('select', $(this)).select2('close');
      return;
    } else {
      var fake = $('.fake', $(this));
      if (fake) {
        replace_fake_select2(fake);
        var input = $('input', $(this));
        input.focus();
        // var ee = jQuery.Event('keydown');
        // ee.which = e.which;
        // $('input', $(this)).trigger(ee);
      }
    }
  }

  function fake_select2_click_event(e) {
    e.stopPropagation();
    replace_fake_select2($(this));
    if (e.type == "click" && e.clientX && e.clientY) {
      $(document.elementFromPoint(e.clientX, e.clientY)).click();
    }
  }

  function active_fake_select2(selector) {
    $('.fake', selector).on('click', fake_select2_click_event);
    selector.on('keydown', fake_select2_key_event);
  }

  function build_fake_select2(container, products, product_ids) {
    data_products = [];
    $.each(products, function(i, product) {
      data_products.push({
        id: product.id,
        code: product.code,
        active: product_ids.indexOf(product.id.toString()) >= 0
      });
    });

    return container.html(SMT['order_arrays/fake_select2']({
      products: data_products
    }));
  }

  function build_total(e, table) {
    var $table = $(table),
      sum_column = [],
      grand_total = {};

    $('tbody tr', $table).each(function(i, tr) {
      var $tr = $(tr),
        sum_row = {},
        total = 0;
      $('td[data-id] select', $tr).each(function(j, select) {
        var vals = $(select).val();
        if (vals) {
          if (!sum_column[j]) {
            sum_column[j] = {
              undefined: 0
            };
          }
          $.each(vals, function(i, val) {
            sum_row[val] = (sum_row[val] || 0) + 1;
            sum_column[j][val] = (sum_column[j][val] || 0) + 1;
          });
        }
      });
      $('td[data-sum-product-id]', $tr).each(function(i, td) {
        var pid = $(td).data('sum-product-id');
        td.innerHTML = sum_row[pid] || '-';
        grand_total[pid] = (grand_total[pid] || 0) + (sum_row[pid] || 0);
        total += sum_row[pid] || 0;
      });
      $('td.total-products', $tr).html(total || '-');
    });

    // Columns
    var product_length = $('tfoot tr').length - 1;
    var row_length = $('tr:first .order', $table).length;
    grand_total[undefined] = 0;
    $('tfoot tr').each(function(i, tr) {
      var $tr = $(tr),
        pid = $('th[data-product_id]', $tr).data('product_id');
      $('td:nth-child(n+4)', $(tr)).each(function(j, td) {
        sum_column[j] = sum_column[j] || {};
        td.innerHTML = sum_column[j] && sum_column[j][pid] || '-';
        sum_column[j][undefined] += sum_column[j][pid] || 0;
      });
      $('td:nth-child(' + (row_length + 4 + i) + ')', $tr).html(grand_total[pid] || '-');
      grand_total[undefined] += grand_total[pid] || 0;
    });
  }

  var products = {};

  function display_order_array(data) {
    var container = $('#order_array div');
    $.each(data.products, function(i, product) {
      products[product.id] = product;
    });
    $.each(data.rows, function(i, row) {
      $.each(row.orders, function(i, order) {
        order.products = [];
        $.each(products, function(i, product) {
          order.products.push({
            id: product.id,
            code: product.code,
            active: order.product_ids.indexOf(product.id) >= 0
          });
        });
      });
    });
    data.i18n = mustache_i18n;
    $(container).html(SMT['order_arrays/index'](data));

    var headers = {
      0: {
        sorter: false
      }
    };
    var filter_functions = {};
    for (var i = 0; i < data.columns.length; i++) {
      headers[i + 3] = {
        sorter: false
      };
      filter_functions[i] = filter_text;
    }
    var filter_formatter = {
      0: function($cell, indx) {
        return false;
      }
    };
    for (var i = 0; i < data.products.length + 1; i++) {
      filter_formatter[i + data.columns.length + 3] = function($cell, indx) {
        return false;
      };
    }
    $("#order_array table").bind("tablesorter-initialized", build_total).tablesorter({
      textExtraction: function(node, table, cellIndex) {
        if (cellIndex >= 3) {
          return $.map($("[name$=\\[product_ids\\]\\[\\]] :selected", node), function(e, i) {
            return e.text;
          }).join(",");
        } else {
          return $(node).text();
        }
      },
      headers: headers,
      theme: "bootstrap",
      // Show order icon v and ^
      headerTemplate: '{content} {icon}',
      widgets: ["uitheme", "stickyHeaders", "filter", "columnSelector"],
      widgetOptions: {
        filter_childRows: true,
        // class name applied to filter row and each input
        filter_cssFilter: "tablesorter-filter",
        filter_functions: filter_functions,
        filter_formatter: filter_formatter
      }
    });

    $('#order_array table thead input').focusin(function() {
      if (table_neeed_update) {
        table_neeed_update = false;
        $("#order_array table").trigger("update");
      }
    });

    active_fake_select2($('td[data-id]'));

    function change_order(product_id, add_product, remove_product, paste, copy, selector) {
      var orders = {};
      block_save_select_change = true;
      selector.each(function(i, td) {
        var val = [];
        if (add_product || remove_product) {
          val = $('select', $(this)).val() || [];
          var index = val.indexOf(product_id);
          if (add_product) {
            if (index < 0) {
              val.push(product_id);
            }
          } else if (remove_product) {
            if (index >= 0) {
              val.splice(index, 1);
            }
          }
        } else if (paste && copy) {
          val = copy[i];
        }
        build_fake_select2($(td), products, val);

        orders[$(this).data('id')] = {
          product_ids: val
        };
      });
      active_fake_select2($('.fake', selector));
      block_save_select_change = false;
      table_neeed_update = true;
      build_total(undefined, $('#order_array table'));

      $.ajax({
        type: "patch",
        data: JSON.stringify({
          orders: orders
        }),
        contentType: "application/json",
        url: '/api/0.1/order_arrays/' + order_array_id + '.json',
        beforeSend: beforeSendWaiting,
        complete: completeWaiting,
        error: ajaxError
      });
    }

    var copy_row;
    $('.copy_row').click(function(e) {
      var tr = $(this).closest('tr');
      copy_row = [];
      $.each($('td[data-id] select', tr), function(i, select) {
        copy_row.push($.map($(select).val() || ['-1'], function(n) {
          return n.toString();
        }));
      });
    });

    $('.empty_row, .paste_row, .add_product_row, .remove_product_row').click(function(e) {
      var tr = $(this).closest('tr'),
        add_product = $(this).hasClass('add_product_row'),
        remove_product = $(this).hasClass('remove_product_row'),
        paste = $(this).hasClass('paste_row'),
        product_id = ($(this).data('product_id') || 0).toString(),
        selector = $('td[data-id]', tr);
      change_order(product_id, add_product, remove_product, paste, copy_row, selector);
    });

    var copy_column;
    $('.copy_column').click(function(e) {
      var td_index = $(this).closest('th').index('th') + 1;
      copy_column = [];
      $('tbody tr td:nth-child(' + td_index + ') select', $(this).closest('table')).each(function(i, select) {
        copy_column.push($.map($(select).val() || ['-1'], function(n) {
          return n.toString();
        }));
      });
    });

    $('.empty_column, .paste_column, .add_product_column, .remove_product_column').click(function(e) {
      var td_index = $(this).closest('th').index('th') + 1,
        add_product = $(this).hasClass('add_product_column'),
        remove_product = $(this).hasClass('remove_product_column'),
        paste = $(this).hasClass('paste_column'),
        product_id = ($(this).data('product_id') || 0).toString();
      selector = $('tbody tr td:nth-child(' + td_index + ')', $(this).closest('table'));
      change_order(product_id, add_product, remove_product, paste, copy_column, selector);
    });

    $('.planning').click(function(e) {
      var index = $(this).closest('th').index('th') - 3,
        planning_id = $(this).data('planning_id').toString();
      $.ajax({
        type: "patch",
        contentType: "application/json",
        url: '/api/0.1/plannings/' + planning_id + '/orders/' + order_array_id + '/' + index + '.json',
        beforeSend: beforeSendWaiting,
        complete: completeWaiting,
        error: ajaxError
      });
    });
  }

  $("#dialog-loading").dialog({
    autoOpen: true,
    modal: true
  });

  $.ajax({
    url: '/order_arrays/' + order_array_id + '.json',
    beforeSend: beforeSendWaiting,
    success: display_order_array,
    complete: function(data) {
      completeWaiting(data);
      $("#dialog-loading").dialog('close');
    },
    error: ajaxError
  });
}

Paloma.controller('OrderArray').prototype.new = function() {
  order_arrays_new(this.params);
};

Paloma.controller('OrderArray').prototype.create = function() {
  order_arrays_new(this.params);
};

Paloma.controller('OrderArray').prototype.edit = function() {
  order_arrays_edit(this.params);
};

Paloma.controller('OrderArray').prototype.update = function() {
  order_arrays_edit(this.params);
};
