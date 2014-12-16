#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Setup NodeJS + Duojs
#   
#   Tested on :
#   Ubuntu 14.04 LTS "trusty"
#   
#   Sources :
#   https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-an-ubuntu-14-04-server
#   http://duojs.org/
#   
#   @timestamp 2014/12/16 00:33:57
#   


#   Add a PPA (personal package archive) maintained by NodeSource
curl -sL https://deb.nodesource.com/setup | sudo bash -

apt-get install nodejs -y

#   Results as of 2014/12/16 00:37:36 :
npm --version
#   1.4.28
node --version
#   v0.10.33


#       Install Duojs globally
#       Note : npm WARN engine koa@0.8.2: wanted: {"node":">= 0.11.9"} (current: {"node":"0.10.33","npm":"1.4.28"})
npm install -g duo

