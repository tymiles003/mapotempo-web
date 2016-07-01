Mapotempo [![Build Status](https://travis-ci.org/Mapotempo/mapotempo-web.svg?branch=dev)](https://travis-ci.org/Mapotempo/mapotempo-web)
=========
Delivery optimization with numerous stops. Based on [OpenStreetMap](http://www.openstreetmap.org) and [OR-Tools](http://code.google.com).

# Installation

For the following installation, your current working directory needs to be the mapotempo-web root directory.

## On Fedora

Install ruby (>2.0 is needed), bundler and some dependencies from system package.

    yum install ruby ruby-devel rubygem-bundler postgresql-devel libgeos++-dev

## On other systems

Install ruby (>2.0 is needed) and other dependencies from system package. For exemple for Ubuntu:
    sudo apt-get install ruby2.0 ruby2.0-dev libz-dev libicu-dev build-essential g++ postgresql-server-dev-9.3 libgeos++-dev

It's important to have those installed packages before installing following gems.

Install ruby bundle gem by :

    export GEM_HOME=~/.gem/ruby/2.0.0
    gem install bundler

## All systems

Now add gem bin directory to path with :

    export PATH=$PATH:~/.gem/ruby/2.0.0/bin

And finally install gem project dependencies with :

    bundle install

# Configuration

Default project configuration is in `config/application.rb` you can override any setting by create a `config/initializers/mapotempo.rb` file and override any variable. In particular you may need to override `Mapotempo::Application.config.trace_cache_dir` and `Mapotempo::Application.config.optimizer_exec`.

Delayed job (background task) can be activated by setting `Mapotempo::Application.config.delayed_job_use = true` it's allow asynchronous running of import geocoder and optimization computation.

Default configuration point on public [OSRM](http://project-osrm.org) API but matrix computation heavily discouraged on it. So point on your own instance.

# Initialization

Check database configuration in `config/database.yml` and from project directory create a database for your environment with :

As postgres user:

    createuser -s [username]

    createdb -E UTF8 -T template0 -O [username] mapotempo-dev

    createdb -E UTF8 -T template0 -O [username] mapotempo-test

As normal user:

    rake db:schema:load RAILS_ENV=development

You can load demo data from `db/seeds.rb` into database with :

    rake db:seed

# Running

Start standalone rails server with

    rails server

Enjoy at [http://localhost:3000](http://localhost:3000)

Start the background jobs runner with

    ./bin/delayed_job run

# Running in production

Setup assets:
    rake i18n:js:export
    rake assets:precompile

# Launch tests

    rake test

If you focus one test only or for any other good reasons, you don't want to check i18n and coverage:
    rake test I18N=false COVERAGE=false
