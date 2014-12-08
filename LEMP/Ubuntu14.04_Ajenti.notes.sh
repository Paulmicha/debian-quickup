#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Based on LEMP
#   test on Ubuntu 14.04 LTS
#   
#   Sources
#   https://github.com/Eugeny/ajenti-v/issues/61
#   
#   @timestamp 2014/12/08 00:30:35
#   


#----------------------------------------------------------------------------
#       Misc


apt-get install htop -y
apt-get install unzip -y
apt-get install git-core -y



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
apt-get install php5-cli -y

#       Curl, gd, mcrypt
apt-get install php5-curl -y
apt-get install php5-gd -y
apt-get install php5-mcrypt -y

#       SQLite3
apt-get install sqlite3 -y
apt-get install php5-sqlite -y

#       Image magick
apt-get install imagemagick -y
apt-get install php5-imagick -y

#       Main php.ini configuration : modif. with sed
sed -e 's,;default_charset = "UTF-8",default_charset = "UTF-8",g' -i.bak /etc/php5/fpm/php.ini
sed -e 's,max_input_time = 60,max_input_time = 120,g' -i /etc/php5/fpm/php.ini
sed -e 's,memory_limit = 128M,memory_limit = 256M,g' -i /etc/php5/fpm/php.ini
sed -e 's,display_errors = Off,display_errors = On,g' -i /etc/php5/fpm/php.ini
sed -e 's,post_max_size = 8M,post_max_size = 130M,g' -i /etc/php5/fpm/php.ini
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 128M,g' -i /etc/php5/fpm/php.ini
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i /etc/php5/fpm/php.ini

#       The interpreter will only process the exact file path — a much safer alternative
sed -e 's,;cgi.fix_pathinfo=1,cgi.fix_pathinfo=0,g' -i /etc/php5/fpm/php.ini

#       More memory allocated for opcode cache
echo "opcache.memory_consumption=384" >> /etc/php5/mods-available/opcache.ini

#       Enable opcode cache for drush
echo "opcache.enable_cli=On" >> /etc/php5/mods-available/opcache.ini

#       Reload config
service php5-fpm restart



#----------------------------------------------------------------------------
#       MariaDB 10.x


#       NB: there's a tool to get mirror & proper version 
#       @see https://downloads.mariadb.org/mariadb/repositories/
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://mirror.edatel.net.co/mariadb//repo/10.1/ubuntu trusty main'

apt-get update

#       Note : this will prompt for root password + confirmation
apt-get install mariadb-server -y

#       PHP Driver (mysql)
apt-get install php5-mysql -y



#----------------------------------------------------------------------------
#       Composer
#       @see https://getcomposer.org/doc/00-intro.md#globally


cd /usr/local/bin
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#       Add Composer's global bin directory to the system PATH (recommended):
sed -i '1i export PATH="$HOME/.composer/vendor/bin:$PATH"' $HOME/.bashrc
source $HOME/.bashrc



#----------------------------------------------------------------------------
#       Php HHVM for Composer
#       @see http://markvaneijk.com/use-hhvm-to-speed-up-composer
#       @see https://github.com/facebook/hhvm/wiki/Prebuilt-packages-on-Ubuntu-14.04


wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list
apt-get update
apt-get install hhvm -y

#       Start at boot
update-rc.d hhvm defaults

#       Always use HHVM for Composer
#       -> create alias
echo "alias composer='hhvm /usr/local/bin/composer'" >> $HOME/.bash_profile
source $HOME/.bash_profile



#----------------------------------------------------------------------------
#       Drush


#       Manual installation (only way working as of 2014/12/08 00:34:09)
mkdir /usr/local/share/drush
cd /usr/local/share/drush
git clone https://github.com/drush-ops/drush.git -b master .
chmod u+x drush
ln -s /usr/local/share/drush/drush /usr/bin/drush
composer install



#----------------------------------------------------------------------------
#       Ajenti + Ajenti V


wget -O- https://raw.github.com/Eugeny/ajenti/master/scripts/install-ubuntu.sh | sudo sh
apt-get install ajenti-v ajenti-v-nginx ajenti-v-mysql ajenti-v-php-fpm -y
service ajenti restart



#----------------------------------------------------------------------------
#       Notes
#       @todo 2014/12/08 03:10:21 - document Ajenti conf


#       test Drupal 7 ok
#       @see https://github.com/Eugeny/ajenti-v/issues/61
mkdir /usr/share/drupal-nginx-conf
echo '# Enable compression, this will help if you have for instance advagg‎ module
# by serving Gzip versions of the files.
gzip_static on;

location = /favicon.ico {
    log_not_found off;
    access_log off;
}

location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
}

location ~ \..*/.*\.php$ {
    return 403;
}

# No no for private
location ~ ^/sites/.*/private/ {
    return 403;
}

# Block access to "hidden" files and directories whose names begin with a
# period. This includes directories used by version control systems such
# as Subversion or Git to store control files.
location ~ (^|/)\. {
    return 403;
}

location / {
# This is cool because no php is touched for static content
    try_files $uri @rewrite;
}

location @rewrite {
    # You have 2 options here
    # For D7 and above:
    # Clean URLs are handled in drupal_environment_initialize().
    rewrite ^ /index.php;
}

# Fighting with Styles? This little gem is amazing.
# This is for D7 and D8
location ~ ^/sites/.*/files/styles/ {
    try_files $uri @rewrite;
}

location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    expires max;
    log_not_found off;
}
' > /usr/share/drupal-nginx-conf/7.conf



#       Ajenti > Websites > (pick one) > "Advanced" tab > "Custom configuration" textarea :
include /usr/share/drupal-nginx-conf/7.conf;





