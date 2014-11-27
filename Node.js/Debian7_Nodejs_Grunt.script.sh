#!/bin/bash
# -*- coding: UTF8 -*-

##
#   NodeJS setup
#   Debian 7 ("Wheezy")
#   
#   tested on 2014/03/21 00:48:05
#   
#   Sources :
#   https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager#debian-lmde
#   https://github.com/joyent/node/wiki/backports.debian.org
#   http://gruntjs.com/getting-started
#


#------------------------------------------------------------------------------------------------------------------------------
#       Node

#       Method 1 : from source (~2/4min)
apt-get install python g++ make checkinstall -y
src=$(mktemp -d) && cd $src
wget -N http://nodejs.org/dist/node-latest.tar.gz
tar xzvf node-latest.tar.gz && cd node-v*
./configure
fakeroot checkinstall -y --install=no --pkgversion $(echo $(pwd) | sed -n -re's/.+node-v(.+)$/\1/p') make -j$(($(nproc)+1)) install
dpkg -i node_*

#       Method 2 : using wheezy-backports (untested)
#echo "deb http://ftp.us.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
#apt-get update
#apt-get install nodejs-legacy
#curl --insecure https://www.npmjs.org/install.sh | bash



#------------------------------------------------------------------------------------------------------------------------------
#       Grunt

npm install -g grunt-cli



