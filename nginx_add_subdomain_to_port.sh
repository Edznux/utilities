#!/bin/bash
NGINX_BASE="/etc/nginx"
NGINX_SITE_AVAILABLE="$NGINX_BASE/sites-available"
NGINX_SITE_ENABLE="$NGINX_BASE/sites-enabled"

# Check root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check arguments
if [ $# -lt 3 ]; then
	echo "Usage :"
	echo "$0 <application-name> <subdomain.domain.tld> <port>"
	exit
fi

touch "$NGINX_SITE_AVAILABLE/$1"

echo "server {
	listen 80;
	server_name $2;

	location / {
		proxy_pass http://localhost:$3;
    }   
}" > "$NGINX_SITE_AVAILABLE/$1"

cat "$NGINX_SITE_AVAILABLE/$1"
read -p "Do you wish to enable this config file ?" yn
case $yn in
	[Yy]* )
		ln -s "$NGINX_SITE_AVAILABLE/$1" "$NGINX_SITE_ENABLE/$1";;
	[Nn]* )
		exit;;
	* ) 
		echo "Please answer yes or no.";;
esac

read -p "Do you wish to restart nginx ?" yn
case $yn in
	[Yy]* ) 
		service nginx restart;;

	[Nn]* )
		exit;;

	* ) 
		echo "Please answer yes or no.";;
esac
