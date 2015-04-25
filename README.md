MapoTempo
=========
Delivery optimization in urban area with numerous stops. Based on [OpenStreetMap](http://www.openstreetmap.org) and [OR-Tools](http://code.google.com).

Installation
============

# On Fedora

Install ruby, bundler and some dependencies from system package.

    yum install ruby ruby-devel rubygem-bundler postgresql-devel

And finally install gem project dependencies with :

    bundle install

# On other systems

Install ruby from system package.
Install ruby bundle gem by :

    export GEM_HOME=~/.gem/ruby/2.0.0
    gem install bundler

Now add gem bin directory to path with :

    export PATH=$PATH:~/.gem/ruby/2.0.0/bin

And finally install gem project dependencies with :

    bundle install

Configuration
=============
Default project configuration is in `config/application.rb` you can override any setting by create a `config/initializers/mapotempo.rb` file and override any variable. In particular you may need to override `Mapotempo::Application.config.trace_cache_dir` and `Mapotempo::Application.config.optimizer_exec`.

Delayed job (background task) can be activated by setting `Mapotempo::Application.config.delayed_job_use = true` it's allow asynchronous running of import geocoder and optimization computation.

`Mapotempo::Application.config.trace_osrm_url` point on public [OSRM](http://project-osrm.org) API but matrix computation heavily discouraged on it. So point on your own instance.

Initialization
==============
Check database configuration in `config/database.yml` and from project directory create a database for your environment with :

    rake db:schema:load RAILS_ENV=development

You can load demo data from `db/seeds.rb` into database with :

    rake db:seed

Running
=======
Start standalone rails server with

    rails server

Enjoy at [http://localhost:3000](http://localhost:3000)

Start the background jobs runner with

    ./bin/delayed_job run
