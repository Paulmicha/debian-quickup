#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Debian 7 Wheezy - Ruby setup
#   
#   Sources :
#   http://snugug.com/musings/installing-sass-and-compass-across-all-platform
#   
#   @author Paulmicha
#   

aptitude install ruby-full build-essential -y
aptitude install rubygems -y

export PATH=/var/lib/gems/1.8/bin:$PATH
gem install compass


