I18n.locale = :fr

mapnik_fr = Layer.create!(source: "osm", name: "Mapnik-fr", url: "http://tile-{s}.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", urlssl: "https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", attribution: "Tiles by OpenStreetMap-France")
mapnik = Layer.create!(source: "osm", name: "Mapnik", url: "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", urlssl: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", attribution: "Tiles by OpenStreetMap")
mapbox = Layer.create!(source: "osm", name: "MapBox Street", url: "http://{s}.tiles.mapbox.com/v3/examples.map-i87786ca/{z}/{x}/{y}.png", urlssl: "https://{s}.tiles.mapbox.com/v3/examples.map-i87786ca/{z}/{x}/{y}.png", attribution: "Tiles by MapBox")
stamen_bw = Layer.create!(source: "osm", name: "Stamen B&W", url: "http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png", urlssl: "https://stamen-tiles-{s}.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.png", attribution: "Tiles by Stamen Design")

here_layer = Layer.create!(source: "here", name: "Here", url: "http://4.base.maps.cit.api.here.com/maptile/2.1/maptile/newest/normal.day/{z}/{x}/{y}/256/png8?app_id=YOUR_APP_ID&app_code=YOUR_APP_CODE", urlssl: "https://4.base.maps.cit.api.here.com/maptile/2.1/maptile/newest/normal.day/{z}/{x}/{y}/256/png8?app_id=YOUR_APP_ID&app_code=YOUR_APP_CODE", attribution: "Here")
#osrm = RouterOsrm.create!(mode: "car", name: "project-osrm.org", url_time:"http://router.project-osrm.org", url_isochrone:"http://localhost:1723", time: true, distance: true)
#here_router = RouterHere.create!(mode: "truck", name: "Here", time: true, distance: true)
car = RouterWrapper.create!(mode: "car", name: "RouterWrapper-Car", url_time:"http://localhost:9090", time: true, distance: true, avoid_zones: false, isochrone: true, isodistance: true)
car_urban = RouterWrapper.create!(mode: "car_urban", name: "RouterWrapper-Car-Urban", url_time:"http://localhost:9090", time: true, distance: true, avoid_zones: false, isochrone: true, isodistance: true)
bicycle = RouterWrapper.create!(mode: "bicycle", name: "RouterWrapper-Bicycle", url_time:"http://localhost:9090", time: true, distance: true, avoid_zones: false, isochrone: true, isodistance: true)
pedestrian = RouterWrapper.create!(mode: "pedestrian", name: "RouterWrapper-Pedestrian", url_time:"http://localhost:9090", time: true, distance: true, avoid_zones: false, isochrone: true, isodistance: true)
truck = RouterWrapper.create!(mode: "truck", name: "RouterWrapper-HereTruck", url_time:"http://localhost:9090", time: true, distance: false, avoid_zones: true, isochrone: true, isodistance: true)
public_transport = RouterWrapper.create!(mode: "public_transport", name: "RouterWrapper-PublicTransport", url_time:"http://localhost:9090", time: true, distance: false, avoid_zones: false, isochrone: true, isodistance: true)

profile_all = Profile.create!(name: "All", layers: [mapnik_fr, mapnik, mapbox, stamen_bw, here_layer], routers: [car, car_urban, bicycle, pedestrian, truck, public_transport])

reseller = Reseller.create!(host: "localhost:3000", name: "Mapotempo")
customer = Customer.create!(reseller: reseller, name: "Toto", default_country: "France", router: car, profile: profile_all, test: true, max_vehicles: 2)
admin = User.create!(email: "admin@example.com", password: "123456789", reseller: reseller, layer: mapnik)
test = User.create!(email: "test@example.com", password: "123456789", layer: mapnik, customer: customer)
toto = User.create!(email: "toto@example.com", password: "123456789", layer: mapnik, customer: customer)

Tag.create!(label: "lundi", customer: customer)
Tag.create!(label: "jeudi", customer: customer)
frigo = Tag.create!(label: "frigo", customer: customer)

Visit.create!(ref: 'v1', quantity: 1, destination: Destination.create!(name: "l1", street: "Place Picard", postalcode: "33000", city: "Bordeaux", lat: 44.84512, lng: -0.578, customer: customer))
Visit.create!(ref: 'v2', quantity: 1, destination: Destination.create!(name: "l2", street: "Rue Esprit des Lois", postalcode: "33000", city: "Bordeaux", lat: 44.83395, lng: -0.56545, customer: customer))
Visit.create!(ref: 'v3', quantity: 1, destination: Destination.create!(name: "l3", street: "Rue de Nuits", postalcode: "33000", city: "Bordeaux", lat: 44.84272, lng: -0.55013, customer: customer))
destination_4 = Destination.create!(name: "l4", street: "Rue de New York", postalcode: "33000", city: "Bordeaux", lat: 44.86576, lng: -0.57577, customer: customer)
Visit.create!(ref: 'v4-1', quantity: 0.5, destination: destination_4, tags: [frigo])
Visit.create!(ref: 'v4-2', quantity: 0.5, destination: destination_4)
