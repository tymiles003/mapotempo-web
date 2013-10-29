class RegistrationsController < Devise::RegistrationsController
  def edit
    js(
      map_layer_url: current_user.layer.url,
      map_lat: current_user.customer.store.lat,
      map_lng: current_user.customer.store.lng,
      map_attribution: t('all.osm_attribution_html', layer_attribution: current_user.layer.attribution),
      layers: Hash[Layer.all.collect{ |layer|
        [layer.id, {url: layer.url, attribution: layer.attribution}]
      }]
    )
    super
  end
end
