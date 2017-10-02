#!/bin/bash

##
# LAMP server quick setup script for local dev (Drupal / Symfony friendly).
#
# Tested on Debian 8.7 "Jessie"
# @timestamp 2017/07/02 17:49:15
#
# Run as root or sudo.
#

mkdir ~/lamp
cd ~/lamp

# System utils.
apt install git -y
apt install curl -y
apt install htop -y
apt install unzip -y

# System : setup unattended security upgrades.
apt install unattended-upgrades apt-listchanges -y
sed -e 's,\/\/Unattended-Upgrade::Mail "root";,Unattended-Upgrade::Mail "root";,g' -i /etc/apt/apt.conf.d/50unattended-upgrades

# Apache.
apt install apache2 -y
a2enmod rewrite
service apache2 restart

# MariaDB.
# Generates MariaDB root password & write it in ~/lamp/.mariadb.env
DB_ROOT_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`
echo "DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD" > ~/lamp/.mariadb.env
DEBIAN_FRONTEND='noninteractive' apt install mariadb-client mariadb-server -y
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_ROOT_PASSWORD}')" | mysql --user=root

# PHP.
apt install php5 php5-dev php5-cli php5-common php5-mysql php5-curl php-pear php5-gd php5-mcrypt -y
apt install php5-intl -y

# PHP SQLite3.
apt install sqlite3 -y
apt install php5-sqlite -y

# PHP Image magik.
apt install imagemagick -y
apt install php5-imagick -y

# PHP Upload Progress.
pecl install uploadprogress
echo -e "extension=uploadprogress.so" > /etc/php5/apache2/conf.d/50-uploadprogress.ini

# PHP UTF-8 for mbstring.
echo -e "; Set mbstring defaults to UTF-8
mbstring.language=UTF-8
mbstring.internal_encoding=UTF-8
mbstring.detect_order=auto" > /etc/php5/apache2/conf.d/20-mbstring.ini

# PHP main configuration (NB: creates a backup on the 1st call).
sed -e 's,memory_limit = 128M,memory_limit = 512M,g' -i.bak /etc/php5/apache2/php.ini
sed -e 's,max_execution_time = 30,max_execution_time = 180,g' -i /etc/php5/apache2/php.ini
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 50M,g' -i /etc/php5/apache2/php.ini
sed -e 's,max_input_time = 60,max_input_time = 120,g' -i /etc/php5/apache2/php.ini
sed -e 's,post_max_size = 8M,post_max_size = 60M,g' -i /etc/php5/apache2/php.ini
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i /etc/php5/apache2/php.ini

# PHP Opcode Cache.
echo "opcache.memory_consumption=384" >> /etc/php5/mods-available/opcache.ini

# PHP Composer.
cd /usr/local/bin
curl -s http://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
composer global require hirak/prestissimo

# PHP Drush 8.x (for D6, D7, D8 <= D8.3).
mkdir /usr/local/share/drush
cd /usr/local/share/drush
git clone https://github.com/drush-ops/drush.git -b 8.x .
chmod u+x drush
ln -s /usr/local/share/drush/drush /usr/bin/drush
composer install



# [optional] Utils.

# PHP Opcode cache status.
cd /var/www/html
wget https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php

# Adminer (DB manager UI).
mkdir /var/www/html/adminer
wget https://github.com/vrana/adminer/releases/download/v4.3.1/adminer-4.3.1-mysql-en.php -O /var/www/html/adminer/index.php
