#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Apache HTTP BasicAuth access restriction
#
#   Tested in :
#   Debian 8 "Jessie"
#   
#   @timestamp 2015/05/11 16:55:10
#   
#   Sources :
#   http://stackoverflow.com/questions/8854909/apache-authentication-except-localhost
#   

#------------------------------------------------------------------------------------------
#       .htaccess (or VHost configuration) contents

#       Example :
nano /path/to/docroot/.htaccess
#       Something like this should do it (adjust path) :
Order allow,deny
Allow from all
Options None
AuthUserFile /path/to/htpasswd-file
AuthName "Title of Authentication"
AuthType Basic
require valid-user


#------------------------------------------------------------------------------------------
#       .htpasswd CRUD

#       Create new passfile (no prompt) :
htpasswd -bc /path/to/htpasswd-file UserName UserPassword

#       Add new access (no prompt)
htpasswd -b /path/to/htpasswd-file UserName UserPassword

#       Delete user
htpasswd -D /path/to/htpasswd-file UserName


#------------------------------------------------------------------------------------------
#       Alternative : only apply for an IP
#       Note : using 127.0.0.1 or "localhost" does NOT work :(
#       @see http://stackoverflow.com/questions/8854909/apache-authentication-except-localhost

# permit by USER || IP
Satisfy any
# USER
AuthUserFile /var/www/munin/.htpasswd
AuthGroupFile /dev/null
AuthName "Password Protected Area"
AuthType Basic
require valid-user
# IP
order deny,allow
deny from all
allow from 123.123.123.123


#------------------------------------------------------------------------------------------
#       Reference

#       htpasswd command :
#htpasswd [-cmdpsD] passwordfile username
#htpasswd -b[cmdpsD] passwordfile username password
#htpasswd -n[mdps] username
#htpasswd -nb[mdps] username password
# -c  Create a new file.
# -n  Don't update file; display results on stdout.
# -m  Force MD5 encryption of the password.
# -d  Force CRYPT encryption of the password (default).
# -p  Do not encrypt the password (plaintext).
# -s  Force SHA encryption of the password.
# -b  Use the password from the command line rather than prompting for it.
# -D  Delete the specified user.


