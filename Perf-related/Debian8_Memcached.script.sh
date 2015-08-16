#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Install memcached
#   
#   Tested on Debian 8 "Jessie"
#   @timestamp 2015/08/02 15:39:53
#   
#   Sources :
#   https://www.digitalocean.com/community/tutorials/how-to-install-and-use-memcache-on-ubuntu-14-04
#   

apt-get install memcached -y
apt-get install php5-memcached -y
service apache2 restart
