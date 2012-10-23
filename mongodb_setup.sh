#!/bin/bash
# -*- coding: UTF8 -*-

##
#   MongoDB installation
#   Debian 6 ("Squeeze")
#
#   Sources :
#   @see http://docs.mongodb.org/manual/tutorial/install-mongodb-on-debian/
#


#------------------------------------------------------------------------------------------
#       Configure Package Management System

#       import the 10gen public GPG Key
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10

#       Create a the /etc/apt/sources.list.d/10gen.list file
#       and include the following line for the 10gen repository
echo -n "deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen" > /etc/apt/sources.list.d/10gen.list

#       Get package
apt-get update

#       Install package
apt-get install mongodb-10gen -y


#------------------------------------------------------------------------------------------
#       Php & MongoDB : PECL installation
#       (requires package "php5-dev")

pecl channel-update pecl.php.net
pecl install mongo
echo -e "extension=mongo.so" > /etc/php5/conf.d/mongo.ini
/etc/init.d/apache2 restart


