#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Debian 7 Wheezy - Ruby setup
#   
#   tested 2014/03/21 01:11:43
#   
#   Sources :
#   http://snugug.com/musings/installing-sass-and-compass-across-all-platform
#   

aptitude install ruby-full build-essential -y
aptitude install rubygems -y

export PATH=/var/lib/gems/1.8/bin:$PATH
gem install compass


