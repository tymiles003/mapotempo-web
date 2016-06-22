#!/bin/env ruby

begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org' do
    gem 'pry'
    gem 'addressable'
    gem 'rest-client'
  end
end

require 'pry'
require 'addressable'
require 'rest-client'
require 'csv'
require 'json'

API_KEY = 'your_secret_api_key'
# URL = 'http://app.beta.mapotempo.com'
URL = 'http://0.0.0.0:3000'

def destinations_url
  Addressable::Template.new("%s/api/0.1/destinations.json{?query*}" % [ URL ]).expand(
    query: { api_key: API_KEY }
  ).to_s
end

def destination_hash index
  {
    ref: "ref-#{index}",
    name: "client-#{index}",
    street: "#{index} Test",
    postalcode: 33000,
    city: "Bordeaux",
    country: "France",
    detail: "this is test #{index}",
    tag_ids: [],
    lat: 44.8798,
    lng: -0.544917,
    visits: [{
      quantity: 1,
      open: "08:00",
      close: "12:00",
      take_over: "00:10:00"
    }]
  }
end

response = RestClient.get destinations_url

puts "Found %s Destinations" % [ JSON.parse(response).length ]

response = RestClient.put destinations_url, { destinations: [destination_hash(1), destination_hash(2)] }.to_json, content_type: :json, accept: :json

puts "Updated %s Destinations" % [ JSON.parse(response).length ]

CSV.open("/tmp/mapotempo_csv", "wb") do |csv|
  csv << ["référence","nom","voie","complément","code postal","ville","lat","lng","tournée","libellés","livré"]
  csv << ["ref-id","Test Name","123 Test","","33000","Bordeaux","44.8798","-0.544917","planning-1","tag-1","T"]
end

# Send Accept-Language => "en" headers when parsing files with header columns in english
response = RestClient::Request.execute method: :put, url: destinations_url, headers: { "Accept-Language" => "fr" }, payload: { multipart: true, file: File.open("/tmp/mapotempo_csv") }
