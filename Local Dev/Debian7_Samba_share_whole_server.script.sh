#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Samba setup - share whole system /
#   Debian 7 ("Wheezy")
#   
#   Sources :
#   http://www.unixmen.com/standalone-samba-in-debian-squeeze/
#   http://ubuntuforums.org/archive/index.php/t-947821.html
#   
#   @timestamp 2015/03/11 14:44:11
#    


##
#   Usage info
#
function usage {
  echo "Install Samba + setup /var/www share for LOCAL dev
Usage :
  ./${SCRIPT_NAME} [ owner (default: current user) ] [ group (default: www-data) ] [ create mask (default: 775) ] [ directory mask (default: 775) ]
"
  exit 1
}

#       Param 1 : owner
#       default : current user
P_OWNER=${1}
if [ -z "${1}" ]; then
    P_OWNER="$USER"
fi

#       Param 2 : group
#       default : current user
P_GROUP=${2}
if [ -z "${2}" ]; then
    P_GROUP="$USER"
fi

#       Param 3 : create mask
#       default : 755
P_CREATE_MASK=${3}
if [ -z "${3}" ]; then
    P_CREATE_MASK="755"
fi

#       Param 4 : directory mask
#       default : 775
P_DIR_MASK=${4}
if [ -z "${4}" ]; then
    P_DIR_MASK="775"
fi



#----------------------------------------------------------------------------
#       Install


apt-get install libcupsys2 samba samba-common -y

#       Sample Config (for local dev only, this is unsafe)
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
create mask = 0$P_CREATE_MASK
directory mask = 0$P_DIR_MASK
force group = $P_GROUP
force create mode
force directory mode

" > /etc/samba/smb.conf

/etc/init.d/samba restart
smbpasswd -a $P_OWNER


