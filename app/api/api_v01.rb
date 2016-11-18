# Copyright © Mapotempo, 2014-2015
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
class ApiV01 < Grape::API
  version '0.1', using: :path

  mount V01::Api

  add_swagger_documentation base_path: 'api', hide_documentation_path: true, info: {
    title: 'API',
    description: ('
<h2>Model</h2>

<p>
<a href="' + Mapotempo::Application.config.swagger_docs_base_path + '/api/0.1/Model-simpel.svg">
  <img src="' + Mapotempo::Application.config.swagger_docs_base_path + '/api/0.1/Model-simpel.svg" width="600"/><br/>
  Simplified view of domain model.
</a>
</p>

<p>Model is structured around four majors concepts: the Customer account, Destinations, Vehicles and Plannings.

<ul>
<li><b><code>Customers</code></b>: many of objects are linked to a customer account (relating to the user calling API). <br>The customer has many users, each user has his own <code>api_key</code>.</li>
<li><b><code>Destinations</code></b>: location points to visit with constraints. The same <code>Destination</code> can be visited several times : in this case several <code>Visit</code>s are associated to one <code>Destination</code>.</li>
<li><b><code>Vehicles</code></b>: vehicles definition are splited in two parts: <ul><li>the structural definition named <code>Vehicle</code> (car, truck, bike, consumption, etc.)</li> <li>and the vehicle usage <code>VehicleUsage</code>, a specific usage of a physical vehicle in a specific context.</li></ul> Vehicles can be used in many contexts called <code>VehicleUsageSet</code> (set of all vehicles usages under a context). Multiple values are only available if dedicated option for customer is active. For instance, if customer needs to use its vehicle 2 times per day (morning and evening), he needs 2 <code>VehicleUsageSet</code> called \'Morning\' and \'Evening\'. <code>VehicleUsageSet</code> defines default values for vehicle usage.</li>
<li><b><code>Plannings</code></b>: <code>Planning</code> is a set of <code>Route</code>s to <code>Visit</code> <code>Destination</code>s with <code>Vehicle</code> within a <code>VehicleUsageSet</code> context. <br>A route is a track between all destinations reached by a vehicle (a new route is created for each customer\'s vehicle and a route without vehicle is created for all out-of-route destinations). By default all customer\'s visites are used in a planning.</li>
</ul>
</p>

<h2>Technical access</h2>

<h3>Swagger descriptor</h3>
<p>This REST API is described with Swagger. The Swagger descriptor defines the request end-points, the parameters and the return values. The API can be addressed by HTTP request or with a generated client using the Swagger descriptor.</p>

<h3>API key</h3>
<p>All access to the API are subject to an <code>api_key</code> parameter in order to authenticate the user.</p>

<h3>Return</h3>
<p>The API supports several return formats: <code>json</code> and <code>xml</code> which depend of the requested extension used in url.</p>

<h3>I18n</h3>
<p>Functionnal textual returns are subject to translation and depend of HTTP header <code>Accept-Language</code>. HTTP error codes are not translated.</p>

<h2>Admin acces</h2>
<p>Using an admin <code>api_key</code> allows advanced opperations (on <code>Customer</code>, <code>User</code>, <code>Vehicle</code>, <code>Profile</code>).</p>

<h2>More concepts</h2>

<h3><code>Profiles</code>, <code>Layers</code>, <code>Routers</code></h3>
<p><code>Profile</code> is a concept which allows to set several other concepts for the customer: 
<ul><li><code>Layer</code>: which allows to choose the background map
<li><code>Router</code>: which allows to build route\'s information.</li></ul></p>

<h3><code>Tags</code></h3>
<p><code>Tag</code> is a concept to filter visits and create planning only for a subset of visits. For instance, if some visits are tagged \'Monday\', it allows to create a new planning for \'Monday\' tag and use only dedicated visits.</p>

<h3><code>Zonings</code></h3>
<p><code>Zoning</code> is a concept which allows to define multiple <code>Zone</code>s (areas) around destinatons. A <code>Zone</code> can be affected to a <code>Vehicle</code> and if it is used into a <code>Planning</code>, all <code>Destinations</code> inside areas will be affected to the zone\'s vehicle (or <code>Route</code>). A polygon defining a <code>Zone</code> can be created outside the application or can be automatically generated from a planning.</p>

<h2>Code samples</h2>
<ul>
  <li>
    <p>Create and display destinations or visits.<br>
    Here some samples for these operations: <a href="' + Mapotempo::Application.config.swagger_docs_base_path + '/api/0.1/examples/php/example.php" target="_blank">using PHP</a>, <a href="' + Mapotempo::Application.config.swagger_docs_base_path + '/api/0.1/examples/ruby/example.rb" target="_blank">using Ruby</a>.<br>
    Note you can import destinations/visits and create a planning at the same time if you know beforehand the route for each destination/visit.</p>
  </li>
  <li>
    <p>Same operations are available for stores (note you have an existing default store).</p>
  </li>
  <li>
    <p>With created destinations/visits, you can create a planning (routes and stops are automatically created depending of yours vehicles and destinations/visits)</p>
  </li>
  <li>
    <p>In existing planning, you have availability to move stops (which represent visits) on a dedicated route (which represent a dedicated vehicle).
  </li>
  <li>
    <p>With many unaffected (out-of-route) stops in a planning, you may create a zoning to move many stops in several routes. Create a zoning (you can generate zones in this zoning automatically from automatic clustering), if you apply zoning (containing zones linked to a vehicle) on your planning, all stops contained in different zones will be moved in dedicated routes.
  </li>
</ul>
').delete("\n"),
  }
end
