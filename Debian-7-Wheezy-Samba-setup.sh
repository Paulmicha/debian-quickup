#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Samba setup
#   Debian 7 ("Wheezy")
#   
#   tested OK 2013/09/18 15:41:20
#   
#   Note 1 : Don't forget to adjust permissions
#   Note 2 : At the end, the script will prompt for password (for the default samba user)
#   
#   If you want to share files between your Debian and Windows computers, your best option is to use Samba file sharing.
#   Samba is a free software re-implementation of SMB/CIFS networking protocol, originally developed by Australian Andrew Tridgell.
#   
#   Warning : the config suggested below is what I use for local dev in my virtual debian install to play at home,
#   which poses massive security issues -> UNSAFE for work.
#   
#   Sources :
#   http://www.unixmen.com/standalone-samba-in-debian-squeeze/
#   http://ubuntuforums.org/archive/index.php/t-947821.html
#   

#       Setup (local dev)
USERNAME="my_username"

#       Initialize Permissions
chown $USERNAME:www-data /var/www -R
chmod 775 /var/www -R

#       Install
aptitude install libcupsys2 samba samba-common -y

#       Sample Config (for local dev only, this is unsafe)
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
echo -n '#       Global Settings
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
[www]
comment = Apache root fully accessible
path = /var/www
read only = No
writable = Yes
create mask = 0775
directory mask = 0775
force group = www-data
force create mode
force directory mode

' > /etc/samba/smb.conf

/etc/init.d/samba restart
smbpasswd -a $USERNAME


