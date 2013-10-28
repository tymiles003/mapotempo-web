function addMap(layer, lat, lng, zoom, attribution) {
  var map = L.map('map').setView([lat, lng], zoom);
  L.tileLayer(layer, {
    maxZoom: 18,
    attribution: attribution
  }).addTo(map);

  return map;
}
