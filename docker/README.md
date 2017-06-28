Using Docker Compose to deploy Mapotempo Web application
========================================================

Building images
---------------


    git clone https://github.com/mapotempo/mapotempo-web mapotempo-web
    cd mapotempo-web/docker
    docker-compose build


Publishing images
-----------------

    docker login
    docker-compose push


Running on a docker host
------------------------

    git clone https://github.com/mapotempo/mapotempo-web mapotempo-web
    cd mapotempo-web/docker
    docker-compose pull
    docker-compose -p app up -d


Initializing database
---------------------

    docker-compose exec --user postgres db psql -c "CREATE ROLE mapotempo PASSWORD 'mapotempo' LOGIN;"
    docker-compose exec --user postgres db psql -c "CREATE DATABASE mapotempo OWNER mapotempo ENCODING 'utf-8';"
    docker-compose exec --user postgres db psql mapotempo -c "CREATE EXTENSION hstore;"
    docker-compose exec --user www-data web bundle exec rake db:setup"
