#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Install memcache
#   Tested on Debian 8 "Jessie"
#   
#   @timestamp 2015/05/12 15:49:17
#   
#   Sources :
#   https://www.digitalocean.com/community/tutorials/how-to-install-and-use-memcache-on-ubuntu-14-04
#   

apt-get install memcached -y

#       Note : this is the Php extension recommended in Drupal's 'memcache' contrib module
apt-get install php5-memcache -y

service apache2 restart

