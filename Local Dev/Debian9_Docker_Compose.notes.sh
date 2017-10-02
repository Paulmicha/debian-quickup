#!/bin/bash

##
# Setup local dev VM Debian 9 for Docker projects.
#
# Prerequisites :
# @see Debian9_common.notes.sh
#
# Tested on Debian 9 "Stretch" on 2017/10/02 14:45:35
# Replace '192.168.0.36' with desired VM LAN IP + adapt 'lan-0-36.io'.
#

# Install Docker Community Edition (CE).

apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common

curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -

add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
  $(lsb_release -cs) \
  stable"

apt-get update
apt-get install docker-ce -y


# Install docker-compose.

curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
