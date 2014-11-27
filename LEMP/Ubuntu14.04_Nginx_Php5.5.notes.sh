#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Local Server quick setup script (to be run as root),
#   for local dev :
#       • Nginx
#       • Php - 5.5 - FPM
#       • MariaDB - 
#       • Composer
#       • HHVM - Facebook's "HipHop Php" JIT compiler + bash alias for Composer
#       • Drush 7 (for Drupal 8) + bash alias
#   
#   (WIP) test in progress on Ubuntu 14.04 LTS "trusty"
#   
#   Sources :
#   https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-12-04
#   https://gist.github.com/cbmd/4247040
#   http://www.stevejenkins.com/blog/2014/07/my-favorite-zend-opcache-status-scripts/
#   
#   @timestamp 2014/11/27 06:30:50
#   


#----------------------------------------------------------------------------
#       Nginx

add-apt-repository ppa:nginx/development
aptitude update
apt-get install nginx -y
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

#       Main php.ini configuration : modif. with sed (NB: creates a backup on the 1st call)
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

#       Util + test
#cd /path/to/wherever
wget http://downloads.sourceforge.net/adminer/adminer-4.1.0-en.php -O adminer.php



#----------------------------------------------------------------------------
#       Nginx PHP-FPM configuration


cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
nano /etc/nginx/sites-available/default
#       Should remain :
#location ~ \.php$ {
#    include snippets/fastcgi-php.conf;
#    fastcgi_pass unix:/var/run/php5-fpm.sock;
#}
location ~ \.php$ {
    try_files $uri =404;
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}

#       Restart Nginx
service nginx restart

#       Ex config dynamic path :
#https://gist.github.com/cbmd/4247040


#       Opcode status
#cd /path/to/wherever
wget https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php



