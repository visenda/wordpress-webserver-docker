#!/bin/bash

echo "Generating wordpress nginx config ..."
printf "\
worker_processes auto;
error_log /dev/stderr info;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;

    $([[ $PROXY_FORWARD_HTTPS == 1 ]] && echo "\
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                      '\$status \$body_bytes_sent \"\$http_referer\" '
                      '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';\
    ")

    access_log /dev/stdout;
    sendfile on;
    keepalive_timeout 2;
	client_max_body_size 100m;
    server_tokens off;

    upstream fastcgi_backend {
        server unix:/var/run/php-fpm.sock;
    }

    server {
        listen 80;
        server_name _;

        root $NGINX_WEBROOT;
        index index.php;

        location = /favicon.ico {
            log_not_found off;
            access_log off;
        }

        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
        }

        location / {
            try_files \$uri \$uri/ /index.php?\$args;
        }

        location ~ \.php$ {
            try_files \$uri =404;
            fastcgi_pass   fastcgi_backend;
            fastcgi_buffers 1024 4k;

            fastcgi_param  PHP_FLAG  \"session.auto_start=off \\\n suhosin.session.cryptua=off\";
            fastcgi_param  PHP_VALUE \"memory_limit=756M \\\n max_execution_time=18000\";
            fastcgi_read_timeout 600s;
            fastcgi_connect_timeout 600s;

            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
            include        fastcgi_params;
        }

        location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
            expires max;
            log_not_found off;
        }
    }
}
" > /etc/nginx/nginx.conf