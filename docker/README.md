Using Docker Compose to deploy Mapotempo Web application
========================================================

Building images
---------------

The following commands will get the source code and build the mapotempo-web
and needed images:

    git clone https://github.com/mapotempo/mapotempo-web mapotempo-web
    cd mapotempo-web/docker
    docker-compose build


Publishing images
-----------------

To pull them from another host, we need to push the built images to
hub.docker.com:

    docker login
    docker-compose push


Running on a docker host
------------------------

First, we need to retrieve the source code and the prebuilt images:

    git clone https://github.com/mapotempo/mapotempo-web mapotempo-web
    cd mapotempo-web/docker
    docker-compose pull

Finally run the services:

    docker-compose -p app up -d


Initializing database
---------------------

After the first deployment, you will need to initialize the database (you may
want to change values for database name, user name and password but don't
forget to update `db.env` file):

    docker-compose exec --user postgres db psql -c "CREATE ROLE mapotempo PASSWORD 'mapotempo' LOGIN;"
    docker-compose exec --user postgres db psql -c "CREATE DATABASE mapotempo OWNER mapotempo ENCODING 'utf-8';"
    docker-compose exec --user postgres db psql mapotempo -c "CREATE EXTENSION hstore;"

Then you can initialize with base data:

    docker-compose exec --user www-data web bundle exec rake db:setup"
