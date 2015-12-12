#!/bin/bash
# -*- coding: UTF8 -*-

##
#   LEMP server quick setup script for local dev (e.g. local VM).
#
#   Drupal friendly (update 2015/12/12 : Symfony untested).
#
#   Tested on Ubuntu 14.04 "Jessie",
#   @timestamp 2015/12/12 13:39:41
#
#   Install (untested 2015/12/12 - WIP) :
#   $ curl -s https://raw.githubusercontent.com/Paulmicha/debian-quickup/master/LEMP/Ubuntu14.04_Nginx_Php7.script.sh | bash /dev/stdin
#
#		Sources :
#		https://bjornjohansen.no/upgrade-to-php7
#		https://github.com/guiajlopes/nginx-drupal-dev
#		https://github.com/guiajlopes/vagrant-drupal-vm
#		http://stackoverflow.com/questions/7325211/tuning-nginx-worker-process-to-obtain-100k-hits-per-min
#


#----------------------------------------------------------------------------
#   Cleanup (if upgrading)


#		Uncomment what's needed here.
# apt-get purge nginx-common -y
# apt-get purge ajenti -y
# apt-get purge apache2 -y
# apt-get purge hhvm -y
# apt-get purge php5-fpm -y
# apt-get purge php5 -y
# apt-get --purge autoremove



#----------------------------------------------------------------------------
#   Prereq. & Misc.


apt-get install htop -y
apt-get install unzip -y
apt-get install git-core -y



#----------------------------------------------------------------------------
#   Nginx


add-apt-repository ppa:nginx/development
apt-get update
apt-get install nginx -y

# For modules : upload-progress, cache-purge
apt-get install nginx-extras -y



#----------------------------------------------------------------------------
#   Php 7.0


apt-get install python-software-properties -y
add-apt-repository ppa:ondrej/php-7.0
apt-get update

apt-get install php7.0-fpm -y

#   Test :
php -v
#   Result (as of 2015/12/12) :
#       PHP 7.0.0-5+deb.sury.org~trusty+1 (cli) ( NTS )
# 			Copyright (c) 1997-2015 The PHP Group
# 			Zend Engine v3.0.0, Copyright (c) 1998-2015 Zend Technologies
#     		with Zend OPcache v7.0.6-dev, Copyright (c) 1999-2015, by Zend Technologies

#   Curl, gd, mcrypt
apt-get install php7.0-curl -y
apt-get install php7.0-gd -y
apt-get install php7.0-mcrypt -y

#   SQLite3
apt-get install sqlite3 -y
apt-get install php7.0-sqlite -y

#   Image magik (postponed)
#   Error : Couldn't find any package by regex 'php7.0-imagick'
# apt-get install imagemagick -y
# apt-get install php7.0-imagick -y

#   Xdebug (postponed)
#   Error : Couldn't find any package by regex 'php7.0-xdebug'
# apt-get install php7.0-xdebug -y

#   Main php.ini configuration : modif. with sed
PHP_CONF=/etc/php/7.0/fpm/php.ini
sed -e 's,max_input_time = 60,max_input_time = 240,g' -i.bak $PHP_CONF
sed -e 's,memory_limit = 128M,memory_limit = 384M,g' -i $PHP_CONF
sed -e 's,display_errors = Off,display_errors = On,g' -i $PHP_CONF
sed -e 's,post_max_size = 8M,post_max_size = 130M,g' -i $PHP_CONF
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 128M,g' -i $PHP_CONF
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i $PHP_CONF

#   The interpreter will only process the exact file path — a much safer alternative
sed -e 's,;cgi.fix_pathinfo=1,cgi.fix_pathinfo=0,g' -i $PHP_CONF

#   More memory allocated for opcode cache
PHP_MODS_GENERAL=/etc/php/mods-available
echo "opcache.memory_consumption=384" >> $PHP_MODS_GENERAL/opcache.ini

#   Reload config
service 'php7.0-fpm' restart



#----------------------------------------------------------------------------
#   MariaDB 10.x


#		(un-re-tested as of 2015/12/12 - already installed previously)
#   NB: there's a tool to get mirror & proper version
#   @see https://downloads.mariadb.org/mariadb/repositories/
# apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
# add-apt-repository 'deb http://mirror.edatel.net.co/mariadb//repo/10.1/ubuntu trusty main'
# apt-get update

#		(un-re-tested as of 2015/12/12 - already installed previously)
#   Note : this will prompt for root password + confirmation
#   @todo test debconf-set-selections with MariaDB + pass root mysql admin credentials as script arg.
#   ex:
#   	debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
#   	debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
# apt-get install mariadb-server -y

#   PHP Driver (mysql)
apt-get install php7.0-mysql -y



#----------------------------------------------------------------------------
#   Nginx Hosts & PHP-FPM configuration


#   Backup default nginx conf.
mkdir -p ~/manual_backups/nginx
tar czf ~/manual_backups/nginx/etc_nginx.folder.bak.tgz /etc/nginx

#   Use @guiajlopes nginx-drupal-dev conf.
#   Note : as of 2015/12/12 master is for Drupal-7.
rm /etc/nginx -r
git clone https://github.com/guiajlopes/nginx-drupal-dev.git /etc/nginx
chmod 0644 /etc/nginx -R

#   Tweaks
#	worker_processes = 2 * Number of CPUs
#	(in this example : using a 4 CPUs VM)
sed -e 's,worker_processes  2,worker_processes 8,g' -i /etc/nginx/nginx.conf

#   Set USER and WEB_DIR manually.
sed -e 's,user {{UNIX_USER}},user www-data,g' -i /etc/nginx/nginx.conf
sed -e 's,{{WEB_DIR}},/var/www/html,g' -i /etc/nginx/nginx.conf


#   @todo 2015/12/12 finish debugging this (it's not working, no time left ;_;)
#   Default VHosts (dynamic config).
#
#       2 default "behaviors" - examples :
#       • http://192.168.123.123/any-folder/      <--- [1]
#       • http://any.domain.tld/                  <--- [2]
#
#       [1] : does NOT require editing one's OS Hosts file
#           (+ bonus : accessible on LAN if VM is bridged - e.g. quick demo for colleagues)
#           In this case, there's only the default "mapping" URL / Folder :
#
#           http://192.168.123.123/any-folder-or-file       --->    /var/www/html/any-folder-or-file
#
#       [2] : requires editing one's OS Hosts file
#           (ex: new line "192.168.123.123 lan-123-123.io"
#             in C:\Windows\System32\drivers\etc\hosts or /etc/hosts)
#           Like in the example from the following link :
#           @see http://trac.nginx.org/nginx/ticket/314
#           I want it to dynamically "map" domain & subdomains to root directories in the following manner :
#
#           http://any.domain.tld/                          --->    /srv/any.domain.tld/docroot

#   Remove initial @guiajlopes config.
rm /etc/nginx/sites-enabled/dev_stage_local

#   Write dynamic VHosts config.
cat > /etc/nginx/sites-enabled/default <<'EOF'
server {

    listen 80 default_server;
    listen [::]:80 default_server;

    set $rootpath "/var/www/html";
    set $domain $host;
    set $case 0;

    # if ($domain ~ "^(.[^.]*)\.([^.]+)$") {
    #     set $domain "$1.$2";
    #     set $rootpath "/var/www/html/${domain}";
    #     set $servername "${domain}";
    #     set $case 1;
    # }

    if ($domain ~ "^(.*)\.(.[^.]*)\.([^.]+)$") {
        set $subdomain $1;
        set $domain "$2.$3";
        set $rootpath "/srv/${domain}.${subdomain}/docroot";
        set $servername "${subdomain}.${domain}";
        set $case 2;
    }

    #   debug
    add_header X-debugco "${case}";
    add_header X-debugrp "${rootpath}";
    add_header X-debugsn "${servername}";
    add_header X-debugsn "${domain}";

    server_name $servername;
    access_log "/var/log/nginx/${servername}.access.log";
    error_log "/var/log/nginx/${servername}.error.log";

    root $rootpath;
    autoindex on;
    index index.html index.php;

    fastcgi_keep_conn on;

    include apps/drupal.conf;
    include apps/php.conf;

    #   @todo 2015/12/12 : test support for per-domain overrides,
    #     by adding new conf files inside /etc/nginx/sites-enabled/.
    #   If you're using a module like search404 then 404's *have *to be handled
    #   by Drupal : uncomment.
    # error_page 404 /index.php;
}
EOF

service nginx reload



#----------------------------------------------------------------------------
#   Composer
#   @see https://getcomposer.org/doc/00-intro.md#globally


#		(un-re-tested as of 2015/12/12 - already installed previously)
# cd /usr/local/bin
# curl -sS https://getcomposer.org/installer | php
# mv composer.phar /usr/local/bin/composer

#   Add Composer's global bin directory to the system PATH (recommended):
# sed -i '1i export PATH="$HOME/.composer/vendor/bin:$PATH"' $HOME/.bashrc
# source $HOME/.bashrc

#		Update composer (if upgrading).
composer self-update



#----------------------------------------------------------------------------
#   Drush


#		(un-re-tested as of 2015/12/12 - already installed previously)
#   Manual installation
# mkdir /usr/local/share/drush
# cd /usr/local/share/drush
# git clone https://github.com/drush-ops/drush.git -b master .
# chmod u+x drush
# ln -s /usr/local/share/drush/drush /usr/bin/drush
# composer install

#		Update drush (if upgrading).
cd /usr/local/share/drush
git fetch --all
git checkout 8.0.x



#----------------------------------------------------------------------------
#   PHP admin Tools


PHP_TOOLS_PATH=/var/www/html
mkdir -p $PHP_TOOLS_PATH

#   Opcode status
#cd /path/to/wherever
wget https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php -O $PHP_TOOLS_PATH/opcache.php

#   Minimalist multi-DB Tool
wget https://www.adminer.org/static/download/4.2.3/adminer-4.2.3-en.php -O $PHP_TOOLS_PATH/adminer.php

#   Perms.
chown $USER:www-data $PHP_TOOLS_PATH -R
chmod 750 $PHP_TOOLS_PATH -R
