#!/bin/bash

printf "\
alias wp=\"php \$NGINX_WEBROOT/../wp-cli.phar --allow-root --path=\$NGINX_WEBROOT\"
" > /root/.bashrc