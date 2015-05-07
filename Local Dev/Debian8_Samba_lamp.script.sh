#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Samba setup
#   Share whole system + Apache default public web directory
#   
#   Tested on Debian 8 ("Jessie")
#   @timestamp 2015/05/07 20:41:26
#    

apt-get install samba samba-common -y

#       Sample Config
#       (common LAMP defaults, edit as needed)
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
echo -n "#       Global Settings
[global]
workgroup = WORKGROUP
server string = %h server
dns proxy = no

#       Debugging/Accounting
log file = /var/log/samba/log.%m
max log size = 1000
syslog = 0
panic action = /usr/share/samba/panic-action %d

#       Authentication
security = user
encrypt passwords = true
passdb backend = tdbsam
obey pam restrictions = yes
unix password sync = yes
passwd program = /usr/bin/passwd %u
passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
pam password change = yes

#       Share Definitions
[whole_system]
comment = Whole system fully shared
path = /
read only = No
writable = Yes
create mask = 0755
directory mask = 0775
force group = $USER
force create mode
force directory mode

[www]
comment = Web
path = /var/www/html
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


