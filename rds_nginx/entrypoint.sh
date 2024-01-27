#!/bin/bash
# entrypoint.sh

# Replace environment variables in NGINX config
envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start Supervisor to manage Nginx and fcgiwrap
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf