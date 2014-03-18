#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Upgrade linux kernel to 3.8.13
#   Debian 7 ("Wheezy")
#   
#   tested 2014/03/18 02:34:24
#   
#   Sources :
#   http://verahill.blogspot.com.br/2013/02/342-compiling-kernel-38-on-debian.html
#   https://www.kernel.org/pub/linux/kernel/v3.0/
#   


apt-get install kernel-package fakeroot build-essential ncurses-dev -y
mkdir ~/tmp
cd ~/tmp
wget http://www.kernel.org/pub/linux/kernel/v3.0/linux-3.8.13.tar.bz2
tar xvf linux-3.8.13.tar.bz2
cd linux-3.8.13/
cat /boot/config-`uname -r`>.config
make oldconfig

#       lots of questions (tldr -> enter pressed forever)

#       2 is the number of threads you wish to launch -- make it equal to the number of cores that you have for optimum performance during compilation
#       ~40min !
time fakeroot make-kpkg -j2 --initrd kernel_image kernel_headers

#       Finally
dpkg -i ../linux-image-3.8.13_3.8.13-10.00.Custom_amd64.deb ../linux-headers-3.8.13_3.8.13-10.00.Custom_amd64.deb
