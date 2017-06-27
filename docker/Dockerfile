FROM mapotempo/nginx-passenger:latest

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ARG TAG
ENV TAG ${TAG:-master}

ENV RAILS_ENV production

ADD . /srv/app/

# Install dependencies
RUN apt-get update && \
    apt-get install -y git build-essential zlib1g-dev libicu-dev g++ libgeos++-dev libpq-dev\
    zlib1g libicu52 libgeos-3.4.2 libpq5 postgresql-client && \
    \
# Install app
    cd /srv/app && \
    rm -Rf docker && \
    bundle install --full-index --without test development && \
    bundle exec rake i18n:js:export && \
    bundle exec rake assets:precompile && \
    \
# Prepare configuration files
    cp config/database.yml.docker config/database.yml && \
    \
# Fix permissions
    chown -R www-data:www-data . && \
    \
# Cleanup Debian packages
    apt-get remove -y git build-essential zlib1g-dev libicu-dev g++ libgeos++-dev libpq-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ADD docker/env.d/* /etc/nginx/env.d/
ADD docker/snippets/* /etc/nginx/snippets/

VOLUME /srv/app/public/uploads

WORKDIR /srv/app
