#!/bin/bash

echo "Setting file permissions..."
find $NGINX_WEBROOT -type f -exec chmod 644 {} \;
find $NGINX_WEBROOT -type d -exec chmod 755 {} \;