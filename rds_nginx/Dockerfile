# Use Nginx base image from Docker Hub
FROM nginx:latest

# Install MySQL client, fcgiwrap, and supervisor
RUN apt-get update && \
    apt-get install -y default-mysql-client fcgiwrap supervisor

# Copy the static HTML and image
COPY ./commit-Logo.jpg /usr/share/nginx/html/commit-Logo.jpg
COPY ./index.html /usr/share/nginx/html/index.html

# Copy the database query script and make it executable
COPY query_db.sh /usr/share/nginx/html/query_db.sh
RUN chmod +x /usr/share/nginx/html/query_db.sh

# Copy the NGINX config template and supervisor configuration
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Entry script to replace env vars and start services
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
