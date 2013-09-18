#!/bin/bash
# -*- coding: UTF8 -*-

##
#   SVN setup - branch 1.8
#   Debian 7 ("Wheezy")
#   
#   tested 2013/09/18 16:00:39
#   hacked 2013/09/18 16:17:57
#   
#   Sources :
#   http://mariobrandt.de/archives/linux/subversion-svn-1-8-on-debian-7-wheezy-724/
#   http://ymartin59.free.fr/wordpress/index.php/2012/11/25/how-to-install-subversion-1-7-from-wandisco-repository-on-debian-wheezy/
#   


#       Method below failed.
#       Hack : manual installation
cd ~
wget http://opensource.wandisco.com/debian/dists/wheezy/svn18/binary-amd64/libserf1_1.2.1-1%2bWANdisco_amd64.deb
dpkg -i libserf1_1.2.1-1+WANdisco_amd64.deb
wget http://opensource.wandisco.com/debian/dists/wheezy/svn18/binary-amd64/libsvn1_1.8.3-1%2bWANdisco_amd64.deb
dpkg -i libsvn1_1.8.3-1+WANdisco_amd64.deb
wget http://opensource.wandisco.com/debian/dists/wheezy/svn18/binary-amd64/subversion_1.8.3-1%2bWANdisco_amd64.deb
dpkg -i subversion_1.8.3-1+WANdisco_amd64.deb
wget http://opensource.wandisco.com/debian/dists/wheezy/svn18/binary-amd64/subversion-tools_1.8.3-1%2bWANdisco_all.deb
dpkg -i subversion-tools_1.8.3-1+WANdisco_all.deb

#       Key to get packets
#       error : Failed to fetch http://opensource.wandisco.com/debian/dists/wheezy/Release  Unable to find expected entry 'svn18/source/Sources' in Release file (Wrong sources.list entry or malformed file)
#wget -q -O - http://opensource.wandisco.com/wandisco-debian.gpg | apt-key add -
#add-apt-repository "deb http://opensource.wandisco.com/debian wheezy svn18"
#apt-get update && apt-get install subversion subversion-tools -y


