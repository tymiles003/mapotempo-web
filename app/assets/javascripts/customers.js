function customers_edit(params) {
  $('#customer_take_over').timeEntry({
    show24Hours: true,
    showSeconds: true,
    initialField: 1,
    defaultTime: new Date(0, 0, 0, 0, 0, 0),
    spinnerImage: ''
  });
}

Paloma.controller('Customer').prototype.new = function () {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.create = function () {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.edit = function () {
  customers_edit(this.params);
};

Paloma.controller('Customer').prototype.update = function () {
  customers_edit(this.params);
};
