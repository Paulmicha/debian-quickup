#!/usr/bin/env bash

##
# LAMP server quick setup script for local dev (Drupal / Symfony friendly).
#
# Tested on Debian 9 "Stretch"
# @timestamp 2017/07/02 11:59:37
#
# Run as root or sudo.
#
# Usage :
# $ chmod +x ~/custom_scripts/debian8_lamp_setup.sh
#
# Sources :
# https://linuxconfig.org/how-to-install-a-lamp-server-on-debian-9-stretch-linux
#

mkdir ~/lamp
cd ~/lamp

# Generates MariaDB root password & write it in ~/lamp/.mariadb.env
DB_ROOT_PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo`
echo "DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD" > ~/lamp/.mariadb.env

# Install MariaDB.
DEBIAN_FRONTEND='noninteractive' apt install mariadb-client mariadb-server -y
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_ROOT_PASSWORD}')" | mysql --user=root

# Install PHP.
apt install curl -y
apt install php -y

# Abandonned (for now, I require php 5 branch, this installs php 7).
