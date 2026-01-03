#:/bin/sh

if echo "$CLOUDURL" | grep -q '^https'; then
  export PROXY_SSL_SERVER_NAME="proxy_ssl_server_name on;"
else
  export PROXY_SSL_SERVER_NAME=""
fi

# Substitute CLOUDURL into Nginx template
envsubst '$CLOUDURL $PORT $PROXY_SSL_SERVER_NAME' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "NGINX listening on PORT=$PORT"
echo "CLOUDURL=$CLOUDURL"
cat /etc/nginx/conf.d/default.conf

# Start Nginx in the foreground
exec nginx -g 'daemon off;'

