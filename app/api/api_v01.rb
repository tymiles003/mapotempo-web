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

  documentation_class = add_swagger_documentation base_path: 'api', hide_documentation_path: true, info: {
    title: 'API',
    description: '
<h2>Model</h2>

<a href="' + Mapotempo::Application.config.swagger_docs_base_path + '/api/0.1/Model-simple.svg">
  <img src="' + Mapotempo::Application.config.swagger_docs_base_path + '/api/0.1/Model-simple.svg" width="600"/><br/>
  Simplified view of domain model.
</a>

Model is structured around four majors concepts the Customer account, Vehicles, Destinations and Plannings.

<ul>
<li><b><code>Customer</code></b>: the customer account using the API. The customer have many users, each user have his own <code>api_key</code>.</li>
<li><b><code>Vehicles</code></b>: Vehicles, VehicleUsage and VehicleUsageSet.</li>
<li><b><code>Destinations</code></b>:</li>
<li><b><code>Plannings</code></b>: Planning and routes.</li>
</ul>

<h2>Technical access</h2>
<p>This REST API is described with Swagger. The Swagger descriptor define the request end-points, the parameters and the return values. The API can be addressed by HTTP request or with a generated client using the Swagger descriptor.</p>

<p>All access to the API are subject to an <code>api_key</code> parameter in order to authenticate the user.</p>

<h2>Admin acces</h2>
<p>Using an admin <code>api_key</code> allow opperations on <code>Customers</code> and <code>Reseller</code>.</p>
',
  }
end
