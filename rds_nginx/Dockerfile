FROM nginx:latest

RUN apt-get update && \
    apt-get install -y default-mysql-client fcgiwrap supervisor

COPY ./commit-Logo.jpg /usr/share/nginx/html/commit-Logo.jpg
COPY ./index.html /usr/share/nginx/html/index.html

COPY query_db.sh /usr/share/nginx/html/query_db.sh
RUN chmod +x /usr/share/nginx/html/query_db.sh

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
