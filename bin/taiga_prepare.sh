#!/bin/bash

pushd /app/taiga-back

# Setup database automatically if needed
if [ -z "$TAIGA_SKIP_DB_CHECK" ]; then
  python /app/checkdb.py
  DB_CHECK_STATUS=$?

  if [ $DB_CHECK_STATUS -eq 1 ]; then
    echo "Failed to connect to database server."
    exit 1
  elif [ $DB_CHECK_STATUS -eq 2 ]; then
    echo "Configuring initial database"
    python manage.py migrate --noinput
    python manage.py loaddata initial_user
    python manage.py loaddata initial_project_templates
    python manage.py loaddata initial_role
  fi
fi

echo "migrate, compile messages, generate static files"
python manage.py migrate --noinput

# Automatically replace "TAIGA_HOSTNAME" with the environment variable
sed -i "s/TAIGA_HOSTNAME/$TAIGA_HOSTNAME/g" /app/conf.json

# Look to see if we should set the "eventsUrl"
if [ ! -z "$RABBIT_PORT_5672_TCP_ADDR" ]; then
  sed -i "s/eventsUrl\": null/eventsUrl\": \"ws:\/\/$TAIGA_HOSTNAME\/events\"/g" /app/conf.json
fi

# Handle enabling SSL
if [ "$TAIGA_SSL" = "True" ]; then
  echo "Enabling SSL support!"
  sed -i "s/http:\/\//https:\/\//g" /app/conf.json
  sed -i "s/ws:\/\//wss:\/\//g" /app/conf.json
  # mv /etc/nginx/ssl.conf /etc/nginx/conf.d/default.conf
fi

popd >> /dev/null
