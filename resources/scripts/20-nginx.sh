#!/bin/bash

echo "Generating wordpress nginx config ..."
printf "\
worker_processes auto;
error_log stderr info;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 3;
	client_max_body_size 100m;
    server_tokens off;

    $([[ $PROXY_FORWARD_HTTPS == 1 ]] && echo "\
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                      '\$status \$body_bytes_sent \"\$http_referer\" '
                      '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';\
    ")

    upstream fastcgi_backend {
        server unix:/var/run/php-fpm.sock;
    }

    server {
        listen 80;
        server_name _;

        root $NGINX_WEBROOT;
        index index.php;

        access_log /dev/stdout;

    $([[ $PROXY_FORWARD_HTTPS == 1 ]] && echo "\
        # Check if Load Balancer handled SSL
        set \$has_https 'off';

        if (\$http_x_forwarded_proto = 'https') {
            set \$has_https 'on';
        }

        real_ip_header X-Forwarded-For;
        set_real_ip_from 172.16.0.0/12;\
    ")

        location = /favicon.ico {
            log_not_found off;
            access_log off;
        }

        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
        }

        location ~ /\. {
            deny all;
        }

        location ~* /(?:uploads|files)/.*\.php$ {
            deny all;
        }

        location / {
            try_files \$uri \$uri/ /index.php?\$args;
        }

        location ~ \.php\$ {
            include fastcgi.conf;
            fastcgi_intercept_errors on;
            fastcgi_pass fastcgi_backend;
            fastcgi_buffers 16 16k;
            fastcgi_buffer_size 32k;

        $([[ $PROXY_FORWARD_HTTPS == 1 ]] && echo "\
            fastcgi_param HTTPS \$has_https;\
        ")
        }

        location ~* \.(js|css|png|jpg|jpeg|gif|ico)\$ {
            expires max;
            log_not_found off;
        }
    }
}
" > /etc/nginx/nginx.conf