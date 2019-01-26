#!/bin/bash

##
# Setup docker and docker-compose.
#
# Tested in Pop!_OS 18.10 on 2019.01.26.
# Tested in Ubuntu 18.04 (LTS) on 2019.01.26.
#
# Sources :
# https://docs.docker.com/v17.09/engine/installation/linux/docker-ce/ubuntu/#install-docker-ce
# https://docs.docker.com/compose/install/
# https://docs.docker.com/v17.09/engine/installation/linux/linux-postinstall/
#


# 1. Install Docker CE

sudo apt-get update

sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common \
  -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

sudo apt-get update

sudo apt-get install docker-ce -y


# 2. Install docker-compose

sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


# 3. Allow current user to run docker commands

sudo groupadd docker
sudo usermod -aG docker $USER

if [ -d "/home/$USER/.docker" ]; then
  sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
  sudo chmod g+rwx "/home/$USER/.docker" -R
fi
