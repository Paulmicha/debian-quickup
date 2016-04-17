#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Samba setup
#   Share whole system (root) + Apache web directory (www)
#   
#   Tested on Debian 8 ("Jessie")
#   @timestamp 2016/04/17 19:56:50
#    

apt-get install samba samba-common -y

#   Sample Config
#   (common LAMP defaults, edit as needed)
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
echo -n "[root]
path = /
create mask = 0755
force user = root
browsable = Yes
writeable = Yes
read only = No

[www]
path = /var/www
read only = No
writable = Yes
create mask = 0755
directory mask = 0775
force group = www-data
force create mode
force directory mode
" > /etc/samba/smb.conf

/etc/init.d/samba restart
smbpasswd -a $USER


