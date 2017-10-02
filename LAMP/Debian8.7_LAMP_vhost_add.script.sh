#!/bin/bash

##
# LAMP server VHost notes.
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 21:07:44
#
# Run as root or sudo.
#
# Usage (pass domain as 1st arg) :
# ./Debian8.7_LAMP_vhost_add.script.sh the-domain.com
#

DOMAIN=${1}

cat > /etc/apache2/sites-available/${DOMAIN}.conf <<EOF
<VirtualHost *:80>

    ServerName $DOMAIN
    # ServerAlias *.$DOMAIN
    # ServerAlias www.$DOMAIN
    ServerAdmin webmaster@localhost

    DocumentRoot /var/www/$DOMAIN/public

    <Directory /var/www/$DOMAIN/public>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN.error.log
    LogLevel warn
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN.access.log combined

</VirtualHost>
EOF

a2ensite $DOMAIN
service apache2 reload
