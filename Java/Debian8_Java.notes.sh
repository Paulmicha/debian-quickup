#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Java setup
#   Tested on Debian 8 "Jessie"
#   
#   @timestamp 2015/05/11 20:05:04
#   
#   Sources :
#   https://packages.debian.org/search?keywords=openjdk-7-jre
#   http://ubuntuforums.org/showthread.php?t=1506461
#   http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html
#   https://www.digitalocean.com/community/tutorials/how-to-manually-install-oracle-java-on-a-debian-or-ubuntu-vps
#   

#       Simplest install :
#       using Debian stable packages
apt-get install openjdk-7-jre-headless -y


#       Notes on different versions :
#       JDK: Java Development Kit
#           Includes a complete JRE plus tools for developing, debugging, and monitoring Java applications.
#       Server JRE: Java Runtime Environment
#           For deploying Java applications on servers. Includes tools for JVM monitoring and tools commonly required for server applications.
#       Headless : does not provide dependencies used for the graphical components

