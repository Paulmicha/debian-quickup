#!/bin/bash
# -*- coding: UTF8 -*-

##
#   NodeJS setup
#   Debian 6 ("Squeeze")
#   
#   Sources :
#   http://unix.stackexchange.com/questions/35679/whats-the-currently-recommended-way-to-install-node-js-on-debian
#

apt-get install python g++ curl libssl-dev -y
mkdir /tmp/nodejs && cd /tmp/nodejs
wget http://nodejs.org/dist/node-latest.tar.gz
tar xzvf node-latest.tar.gz && cd node-v*
./configure
make
make test
make install
