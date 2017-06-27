Using Docker to deploy App
==========================

    git clone https://github.com/mapotempo/mapotempo-web mapotempo-web
    cd mapotempo-web/docker
    docker-compose -p app up -d

The first time we need to initialize the database:

    docker-compose exec --user postgres db psql -c "CREATE ROLE mapotempo PASSWORD 'mapotempo' LOGIN;"
    docker-compose exec --user postgres db psql -c "CREATE DATABASE mapotempo OWNER mapotempo ENCODING 'utf-8';"
    docker-compose exec --user postgres db psql mapotempo -c "CREATE EXTENSION hstore;"
    docker-compose exec --user www-data web bundle exec rake db:setup"

The application will be available on the port 80 of the host.
