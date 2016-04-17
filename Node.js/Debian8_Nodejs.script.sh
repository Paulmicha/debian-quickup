#!/bin/bash
# -*- coding: UTF8 -*-

##
#   NodeJS setup
#   Debian 8 ("Jessie")
#   
#   @timestamp 2016/04/17 20:25:18
#   
#   Sources :
#   http://unix.stackexchange.com/questions/207591/how-to-install-latest-nodejs-on-debian-jessie
#

#   (As root)
curl -sL https://deb.nodesource.com/setup_4.x | bash -
apt-get install nodejs -y
