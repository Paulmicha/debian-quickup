#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Munin setup
#   Debian 6 ("Squeeze")
#
#   Either use Munin to monitor another server,
#   or use it on a signle server in a "self-monitoring" fashion.
#
#   Munin communicates in a client daemon way.
#   The master-package is the munin package, it collects data from a local or remote daemon.
#   The daemon is called munin-node the node collects data on the local machine.
#   munin-node will allow one or more masters to collect data to a central location where the munin master is running.
#   
#   Sources :
#   http://www.debian-administration.org/articles/597
#   http://munin-monitoring.org/
#   http://blog.nicolargo.com/2012/01/installation-et-configuration-de-munin-le-maitre-des-graphes.html
#


#------------------------------------------------------------------------------------------
#       Single server (self-monitoring setup)

apt-get install munin munin-node munin-plugins-extra -y
ln -s /var/cache/munin/www /var/www/munin

#       Apache config : secure access with htpasswd
#htpasswd -bc /etc/munin/munin-htpasswd Munin MYHTPASS
htpasswd -c /etc/munin/munin-htpasswd Munin
mv /etc/munin/apache.conf /etc/munin/apache.conf.bak
echo -n 'Alias /munin /var/cache/munin/www
<Directory /var/cache/munin/www>
    
    Order allow,deny
    Allow from all
    Options None

    AuthUserFile /etc/munin/munin-htpasswd
    AuthName "Munin"
    AuthType Basic
    require valid-user

    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresDefault M310
    </IfModule>
    
</Directory>' > /etc/munin/apache.conf

#       Finally
/etc/init.d/apache2 restart
/etc/init.d/munin-node restart



#------------------------------------------------------------------------------------------
#       Reference

#       htpasswd command :
#htpasswd [-cmdpsD] passwordfile username
#htpasswd -b[cmdpsD] passwordfile username password
#htpasswd -n[mdps] username
#htpasswd -nb[mdps] username password
#htpasswd -b /etc/munin/munin-htpasswd Munin
# -c  Create a new file.
# -n  Don't update file; display results on stdout.
# -m  Force MD5 encryption of the password.
# -d  Force CRYPT encryption of the password (default).
# -p  Do not encrypt the password (plaintext).
# -s  Force SHA encryption of the password.
# -b  Use the password from the command line rather than prompting for it.
# -D  Delete the specified user.

