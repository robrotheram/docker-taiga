#!/bin/bash
set -e

CONF_DIR=/app/taiga-back
WSGI_FILE=${CONF_DIR}/taiga/wsgi.py

if [ ! -e "$WSGI_FILE" ]; then
    echo "Expected to find $WSGI_FILE"
    exit 1
fi

cd ${CONF_DIR}
exec /usr/local/bin/gunicorn -b 127.0.0.1:8000 --pythonpath ${CONF_DIR} taiga.wsgi:application
