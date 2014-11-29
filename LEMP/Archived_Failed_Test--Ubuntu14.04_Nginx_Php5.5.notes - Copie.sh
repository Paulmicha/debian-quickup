#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Local Server quick setup script (to be run as root),
#   for local dev - as of 2014/11/28 01:42:13 :
#       • Nginx - 1.7.7
#       • Php-FPM - 5.5
#       • MariaDB - 10.1
#       • Git - 1.9.1
#       • Auto-signed certificate
#       • Custom Nginx dynamic hosts setup (Drupal-friendly, adapting perusio/drupal-with-nginx configuration)
#       • [todo] Composer
#       • [todo] HHVM - Facebook's "HipHop" JIT Php compiler + bash alias for Composer
#       • [todo] Drush 7 (for Drupal 8) + bash alias
#   
#   (WIP) test on Ubuntu 14.04 LTS "trusty"
#   
#   Sources :
#   http://flocondetoile.fr/blog/ameliorer-les-performances-de-drupal-avec-nginx
#   https://github.com/perusio/drupal-with-nginx
#   https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-12-04
#   https://gist.github.com/cbmd/4247040
#   http://www.stevejenkins.com/blog/2014/07/my-favorite-zend-opcache-status-scripts/
#   http://superuser.com/questions/389766/linux-bash-how-to-get-interfaces-ipv6-address
#   https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-ubuntu-12-04
#   https://www.digitalocean.com/community/tutorials/how-to-configure-ocsp-stapling-on-apache-and-nginx
#   http://nginx.org/en/docs/http/server_names.html
#   http://trac.nginx.org/nginx/ticket/314
#   
#   @timestamp 2014/11/29 17:40:36
#   


#----------------------------------------------------------------------------
#       Nginx

add-apt-repository ppa:nginx/development
aptitude update
apt-get install nginx -y

#       For modules : upload-progress, cache-purge
apt-get install nginx-extras -y


#----------------------------------------------------------------------------
#       Php 5.5
#       (default in Ubuntu 14.04 LTS "trusty" as of 2014/11/27 04:59:32)

apt-get install php5-fpm -y


#----------------------------------------------------------------------------
#       Php extensions & config

#       Cli
apt-get install php5-cli -y

#       Test :
php -v
#       Result (as of 2014/11/27 05:01:28) :
#           PHP 5.5.9-1ubuntu4.5 (cli) (built: Oct 29 2014 11:59:10)
#           Copyright (c) 1997-2014 The PHP Group
#           Zend Engine v2.5.0, Copyright (c) 1998-2014 Zend Technologies
#               with Zend OPcache v7.0.3, Copyright (c) 1999-2014, by Zend Technologies

#       Curl, gd, mcrypt
apt-get install php5-curl -y
apt-get install php5-gd -y
apt-get install php5-mcrypt -y

#       SQLite3
apt-get install sqlite3 -y
apt-get install php5-sqlite -y

#       Image magik
apt-get install imagemagick -y
apt-get install php5-imagick -y

#       Xdebug (optional, untested)
#apt-get install php5-xdebug -y

#       Main php.ini configuration : modif. with sed
#       (NB: creates a backup on the 1st call - notice the argument -i.bak vs -i on subsequent calls)
#       @see http://stackoverflow.com/questions/3984824/sed-command-in-bash
#       @see http://serverfault.com/questions/551854/is-it-possible-to-auto-update-php-ini-via-a-bash-script
sed -e 's,;default_charset = "UTF-8",default_charset = "UTF-8",g' -i.bak /etc/php5/fpm/php.ini
sed -e 's,max_input_time = 60,max_input_time = 120,g' -i /etc/php5/fpm/php.ini
sed -e 's,memory_limit = 128M,memory_limit = 256M,g' -i /etc/php5/fpm/php.ini
sed -e 's,display_errors = Off,display_errors = On,g' -i /etc/php5/fpm/php.ini
sed -e 's,post_max_size = 8M,post_max_size = 130M,g' -i /etc/php5/fpm/php.ini
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 128M,g' -i /etc/php5/fpm/php.ini
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i /etc/php5/fpm/php.ini

#       The interpreter will only process the exact file path — a much safer alternative
sed -e 's,;cgi.fix_pathinfo=1,cgi.fix_pathinfo=0,g' -i /etc/php5/fpm/php.ini

#       Reload config
service 'php5-fpm' 'restart'


#----------------------------------------------------------------------------
#       MariaDB 10.x

#       NB: there's a tool to get mirror & proper version 
#       @see https://downloads.mariadb.org/mariadb/repositories/
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://mirror.edatel.net.co/mariadb//repo/10.1/ubuntu trusty main'

apt-get update
apt-get install mariadb-server -y

#       PHP Driver (mysql)
apt-get install php5-mysql -y

#       Minimalist multi-DB Tool
#cd /path/to/wherever
wget http://downloads.sourceforge.net/adminer/adminer-4.1.0-en.php -O adminer.php


#----------------------------------------------------------------------------
#       Perusio Nginx configuration includes SSL
#       -> install auto-signed certificate for local dev
#       @see Security/Debian7_SSL.notes.sh

apt-get install openssl ssl-cert -y
mkdir --parent '/etc/ssl/private'
mkdir --parent '/etc/ssl/requests'
mkdir --parent '/etc/ssl/roots'
mkdir --parent '/etc/ssl/chains'
mkdir --parent '/etc/ssl/certificates'
mkdir --parent '/etc/ssl/authorities'
mkdir --parent '/etc/ssl/configs'
chown -R root:ssl-cert '/etc/ssl/private'
chmod 710 '/etc/ssl/private'
chmod 440 '/etc/ssl/private/'*

#       Auto-signed (for LAN)
SSL_KEY_NAME="$(hostname --fqdn)"
CONF_FILE="$(mktemp)"
sed -e "s/@HostName@/${SSL_KEY_NAME}/" \
    -e "s|privkey.pem|/etc/ssl/private/${SSL_KEY_NAME}.key|" \
    '/usr/share/ssl-cert/ssleay.cnf' > "${CONF_FILE}"
openssl req -config "${CONF_FILE}" -new -x509 -days 3650 \
    -nodes -out "/etc/ssl/certificates/${SSL_KEY_NAME}.crt" -keyout "/etc/ssl/private/${SSL_KEY_NAME}.key"
rm "${CONF_FILE}"
chown root:ssl-cert "/etc/ssl/private/${SSL_KEY_NAME}.key"
chmod 440 "/etc/ssl/private/${SSL_KEY_NAME}.key"


#----------------------------------------------------------------------------
#       Nginx Hosts & PHP-FPM configuration
#       (using perusio/drupal-with-nginx)

cd ~
tar czf ~/etc_nginx_dir_backup.tgz /etc/nginx
rm /etc/nginx -r
git clone https://github.com/perusio/drupal-with-nginx.git /etc/nginx
mkdir /etc/nginx/sites-enabled

#       Bug with aio in /etc/nginx/apps/drupal/drupal.conf
#       @see https://github.com/perusio/drupal-with-nginx/issues/136
#       -> deactivate
sed -e 's,aio on;,#aio on;,g' -i /etc/nginx/apps/drupal/drupal.conf

#       Replace hardcoded ipv6
#       @see http://superuser.com/questions/389766/linux-bash-how-to-get-interfaces-ipv6-address
#       update 2014/11/29 18:30:27 FAILS (again. #Tired)
#sed -e 's,\[fe80::202:b3ff:fe1e:8328\],\['"$(command ip addr show dev eth0 | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d')"'\],g' -i /etc/nginx/sites-available/000-default
#sed -e 's,\[fe80\:\:202\:b3ff\:fe1e\:8329\],\['"$(command ip addr show dev eth0 | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d')"'\],g' -i /etc/nginx/sites-available/example.com.conf
#       -> @evol replace with wildcard ?
#       @see http://www.cyberciti.biz/faq/nginx-ipv6-configuration/
#sed -e 's,\[fe80\:\:202\:b3ff\:fe1e\:8328\],\[\:\:\],g' -i /etc/nginx/sites-available/example.com.conf
#sed -e 's,\[fe80\:\:202\:b3ff\:fe1e\:8329\],\[\:\:\],g' -i /etc/nginx/sites-available/example.com.conf
#sed -e 's,\[fe80\:\:202\:b3ff\:fe1e\:8330\],\[\:\:\],g' -i /etc/nginx/sites-available/example.com.conf
#       re-Fails 2014/11/29 18:36:33 (duplicate listen options for [::]:80)
#       -> remove entirely.
sed -e 's,listen \[,#listen \[,g' -i /etc/nginx/sites-available/example.com.conf

#       Replace example certificate
#       @evol https://www.digitalocean.com/community/tutorials/how-to-configure-ocsp-stapling-on-apache-and-nginx
sed -e 's,/etc/ssl/certs/example-cert.pem,/etc/ssl/certificates/'$(hostname --fqdn)'.crt,g' -i /etc/nginx/sites-available/example.com.conf
sed -e 's,/etc/ssl/private/example.key,/etc/ssl/private/'$(hostname --fqdn)'.key,g' -i /etc/nginx/sites-available/example.com.conf

#       Fix nginx: [warn] "ssl_stapling" ignored, issuer certificate not found
#       @evol https://www.digitalocean.com/community/tutorials/how-to-configure-ocsp-stapling-on-apache-and-nginx
sed -e 's,ssl_stapling on;,#ssl_stapling on;,g' -i /etc/nginx/nginx.conf
sed -e 's,resolver 8.8.8.8;,#resolver 8.8.8.8;,g' -i /etc/nginx/nginx.conf

#       FPM specific
sed -e 's,#include php_fpm_status_allowed_hosts.conf;,include php_fpm_status_allowed_hosts.conf;,g' -i /etc/nginx/nginx.conf

#       Microcache folder
mkdir --parent /var/cache/nginx/microcache

#       Fix perms
find /etc/nginx -type f -exec chmod 644 {} +
find /etc/nginx -type d -exec chmod 755 {} +
chmod 755 /var/cache/nginx/microcache


#       This is designed for my local dev VM (with Samba share, cli tools, etc),
#       and I will want to support 2 "behaviors" - examples :
#
#       • http://192.168.123.123/example.com/dev/       <--- [1]
#       • http://192.168.123.123/any-folder/            <--- [1']
#       • http://dev.lan-123-123.io/                    <--- [2]
#       • http://example.com/                           <--- [2']
#
#       [1] : does NOT require editing one's OS Hosts file
#           (+ bonus : accessible on LAN if VM is bridged - e.g. quick demo for colleagues)
#           In this case, there's only the default "mapping" URL / Folder :
#
#           http://192.168.123.123/example.com/dev/     --->    /var/www/example.com/dev/
#
#       [2] : requires editing one's OS Hosts file
#           (ex: new line "192.168.123.123 lan-123-123.io" in C:\Windows\System32\drivers\etc\hosts)
#           Like in the example from the following link :
#           @see http://trac.nginx.org/nginx/ticket/314
#           I want it to dynamically "map" domain & subdomains to root directories in the following manner :
#
#           http://www.example.com/                     --->        /var/www/example.com/www/
#           http://www.lan-123-123.io/                  --->        /var/www/lan-123-123.io/www/
#           http://dev.lan-123-123.io/                  --->        /var/www/lan-123-123.io/dev/
#
#           Ideally, this exception should be handled (to avoid messing up the "subdomain = subdir" pattern) :
#
#           http://lan-123-123.io/                      --->        /var/www/lan-123-123.io/www/


#       Nginx Hosts [1] : Implement Default configuration
#       @see http://nginx.org/en/docs/http/server_names.html
cp /etc/nginx/sites-available/example.com.conf ~
mv /etc/nginx/sites-available/example.com.conf /etc/nginx/sites-available/_.conf
sed -e 's,server_name example.com,server_name _,g' -i /etc/nginx/sites-available/_.conf
sed -e 's,server_name www.example.com,server_name www.$hostname,g' -i /etc/nginx/sites-available/_.conf
sed -e 's,://example.com,://$hostname,g' -i /etc/nginx/sites-available/_.conf
sed -e 's,/var/www/sites/example.com,/var/www,g' -i /etc/nginx/sites-available/_.conf
sed -e 's,#include php_fpm_status_vhost.conf;,include php_fpm_status_vhost.conf;,g' -i /etc/nginx/sites-available/_.conf
sed -e 's,/var/log/nginx/example.com,/var/log/nginx/${hostname},g' -i /etc/nginx/sites-available/_.conf

#       Replace example certificate (per-conf)
#       @evol https://www.digitalocean.com/community/tutorials/how-to-configure-ocsp-stapling-on-apache-and-nginx
#sed -e 's,/etc/ssl/certs/example-cert.pem,/etc/ssl/certificates/'$(hostname --fqdn)'.crt,g' -i /etc/nginx/sites-available/_.conf
#sed -e 's,/etc/ssl/private/example.key,/etc/ssl/private/'$(hostname --fqdn)'.key,g' -i /etc/nginx/sites-available/_.conf

ln -s /etc/nginx/sites-available/_.conf /etc/nginx/sites-enabled/_.conf


#       Nginx Hosts [2] : Implement Dynamic configuration
#       @see http://trac.nginx.org/nginx/ticket/314
#   server_name ~^(?<sub>.+?)\.(?<dom>.+)$;
#   root /srv/www/html/$dom/$sub/public;
#cp ~/example.com.conf /etc/nginx/sites-available/example.com.conf
#mv /etc/nginx/sites-available/example.com.conf /etc/nginx/sites-available/dynhosts.conf
#sed -e 's,server_name example.com,server_name \~\^\(\?<sub>.\+\?\)\\\.\(\?<dom>.\+\)\$,g' -i /etc/nginx/sites-available/dynhosts.conf
#sed -e 's,/var/www/sites/example.com,/var/www,g' -i /etc/nginx/sites-available/dynhosts.conf
#ln -s /etc/nginx/sites-available/_.conf /etc/nginx/sites-enabled/dynhosts.conf



#       Restart Nginx
service nginx restart





#       Ex config dynamic path :
#https://gist.github.com/cbmd/4247040

#       Opcode status
#cd /path/to/wherever
wget https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php



