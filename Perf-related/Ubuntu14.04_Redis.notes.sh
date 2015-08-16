#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Install Redis
#   
#   Tested on Ubuntu 14.04 LTS
#   (as root)
#   @timestamp 2015/08/16 22:08:01
#   
#   Sources
#   http://phpave.com/how-to-install-phpredis-on-ubuntu-1404-lts/
#   https://github.com/phpredis/phpredis
#   https://github.com/charleshross/soarin/wiki/Setup-PHP-Redis-Extension
#   https://www.drupal.org/project/redis
#   

#------------------------------------------------------------------------------
#   Install option 1 : via apt

#   Warning : this will install redis-server version 2.8.4
#   (as of 2015/08/16 22:08:35)
#apt-get install redis-server


#------------------------------------------------------------------------------
#   Install option 2 : Make from sources

cd ~
apt-get install make gcc build-essential -y
wget http://download.redis.io/releases/redis-3.0.3.tar.gz
tar xzf redis-3.0.3.tar.gz
cd redis-3.0.3
make

#   Setup in proper locations.
make install

#   Run once (manually).
#   @todo use supervisor (provide quick setup instructions).
redis-server


#------------------------------------------------------------------------------
#   Redis php recommended module : Phpredis

cd ~
apt-get install php5-dev -y
git clone https://github.com/phpredis/phpredis.git
cd phpredis/
phpize
./configure
make && make install

#   Load the extension.
#   Note : current example uses a php-fpm setup.
echo "extension=redis.so" > /etc/php5/fpm/conf.d/20-redis.ini
service php5-fpm restart
