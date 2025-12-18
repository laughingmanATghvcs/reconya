# Use Nginx (Lightweight web server)
FROM nginx:alpine

# Copy your files to the Nginx web folder
COPY . /usr/share/nginx/html

# Expose port 80 (Standard web port)
EXPOSE 80
