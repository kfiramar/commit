# Use Nginx base image from Docker Hub
FROM nginx:latest

COPY ./commit-Logo.jpg /usr/share/nginx/html/commit-Logo.jpg

# Create a new index.html file
RUN echo '<html>' > /usr/share/nginx/html/index.html
RUN echo '<head><title>Hello Commit</title></head>' >> /usr/share/nginx/html/index.html
RUN echo '<body>' >> /usr/share/nginx/html/index.html
RUN echo 'Hello Commit' >> /usr/share/nginx/html/index.html
RUN echo '<img src="commit-Logo.jpg" alt="commit Logo style="max-width:10%;height:auto;">' >> /usr/share/nginx/html/index.html
RUN echo '</body>' >> /usr/share/nginx/html/index.html
RUN echo '</html>' >> /usr/share/nginx/html/index.html