#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Local Server quick setup script (to be run as root),
#   for local dev - as of 2014/11/28 01:42:13 :
#       • Nginx - 1.7.7
#       • Php-FPM - 5.5
#       • MariaDB - 10.1
#       • Git - 1.9.1
#       • Auto-signed certificate
#       • Custom Nginx dynamic hosts setup (Drupal-friendly, adapting perusio/drupal-with-nginx configuration)
#       • [todo] Composer
#       • [todo] HHVM - Facebook's "HipHop" JIT Php compiler + bash alias for Composer
#       • [todo] Drush 7 (for Drupal 8) + bash alias
#   
#   (WIP) test on Ubuntu 14.04 LTS "trusty"
#   
#   Sources :
#   http://flocondetoile.fr/blog/ameliorer-les-performances-de-drupal-avec-nginx
#   https://github.com/perusio/drupal-with-nginx
#   https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-12-04
#   https://gist.github.com/cbmd/4247040
#   http://www.stevejenkins.com/blog/2014/07/my-favorite-zend-opcache-status-scripts/
#   http://superuser.com/questions/389766/linux-bash-how-to-get-interfaces-ipv6-address
#   https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-ubuntu-12-04
#   https://www.digitalocean.com/community/tutorials/how-to-configure-ocsp-stapling-on-apache-and-nginx
#   http://nginx.org/en/docs/http/server_names.html
#   http://trac.nginx.org/nginx/ticket/314
#   http://serverfault.com/a/459572/128304
#   
#   @timestamp 2014/11/30 04:34:50
#   


#----------------------------------------------------------------------------
#       Samba share
#       Typical local VM setup in bridged network
#       -> share the WHOLE filesystem for convenience

P_OWNER="$USER"
P_GROUP="$USER"
P_CREATE_MASK="640"
P_DIR_MASK="750"

apt-get install samba samba-common -y

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

#       This will prompt for password + confirmation
smbpasswd -a $P_OWNER



#----------------------------------------------------------------------------
#       Nginx

add-apt-repository ppa:nginx/development
aptitude update
apt-get install nginx -y

#       For modules : upload-progress, cache-purge
apt-get install nginx-extras -y


#----------------------------------------------------------------------------
#       Php 5.5
#       (default in Ubuntu 14.04 LTS "trusty" as of 2014/11/27 04:59:32)

apt-get install php5-fpm -y


#----------------------------------------------------------------------------
#       Php extensions & config

#       Cli
apt-get install php5-cli -y

#       Test :
php -v
#       Result (as of 2014/11/27 05:01:28) :
#           PHP 5.5.9-1ubuntu4.5 (cli) (built: Oct 29 2014 11:59:10)
#           Copyright (c) 1997-2014 The PHP Group
#           Zend Engine v2.5.0, Copyright (c) 1998-2014 Zend Technologies
#               with Zend OPcache v7.0.3, Copyright (c) 1999-2014, by Zend Technologies

#       Curl, gd, mcrypt
apt-get install php5-curl -y
apt-get install php5-gd -y
apt-get install php5-mcrypt -y

#       SQLite3
apt-get install sqlite3 -y
apt-get install php5-sqlite -y

#       Image magik
apt-get install imagemagick -y
apt-get install php5-imagick -y

#       Xdebug (optional, untested)
#apt-get install php5-xdebug -y

#       Main php.ini configuration : modif. with sed
sed -e 's,;default_charset = "UTF-8",default_charset = "UTF-8",g' -i.bak /etc/php5/fpm/php.ini
sed -e 's,max_input_time = 60,max_input_time = 120,g' -i /etc/php5/fpm/php.ini
sed -e 's,memory_limit = 128M,memory_limit = 256M,g' -i /etc/php5/fpm/php.ini
sed -e 's,display_errors = Off,display_errors = On,g' -i /etc/php5/fpm/php.ini
sed -e 's,post_max_size = 8M,post_max_size = 130M,g' -i /etc/php5/fpm/php.ini
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 128M,g' -i /etc/php5/fpm/php.ini
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i /etc/php5/fpm/php.ini

#       The interpreter will only process the exact file path — a much safer alternative
sed -e 's,;cgi.fix_pathinfo=1,cgi.fix_pathinfo=0,g' -i /etc/php5/fpm/php.ini

#       Reload config
service 'php5-fpm' restart


#----------------------------------------------------------------------------
#       MariaDB 10.x

#       NB: there's a tool to get mirror & proper version 
#       @see https://downloads.mariadb.org/mariadb/repositories/
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://mirror.edatel.net.co/mariadb//repo/10.1/ubuntu trusty main'

apt-get update

#       Note : this will prompt for root password + confirmation
apt-get install mariadb-server -y

#       PHP Driver (mysql)
apt-get install php5-mysql -y


#----------------------------------------------------------------------------
#       Nginx Hosts & PHP-FPM configuration
#       (NOT using perusio/drupal-with-nginx)

#       Backup original nginx config
mkdir --parent ~/manual_backups/nginx
tar czf ~/manual_backups/nginx/entire-dir-etc-nginx.tgz /etc/nginx

#       Cleanup defaults
rm /var/www/html -R

#       test 2014/11/29 20:12:59 OK
#       contents of /etc/nginx/sites-available/default :
server {
	
	listen 80 default_server;
	listen [::]:80 default_server;
	root /var/www;
	index index.php index.html index.htm;
	server_name _;
	
	location / {
		try_files $uri $uri/ =404;
	}

	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/var/run/php5-fpm.sock;
	}
	
}

#       Then reload :
service nginx restart

#       Contents of /var/www/index.php for test
<?php phpinfo();

#       Permissions
chown root:www-data /var/www -R
find /var/www -type f -exec chmod 644 {} +
find /var/www -type d -exec chmod 755 {} +

#       visit http://192.168.0.25/ (or whatever tour server is)
#       -> tested ok 2014/11/29 20:18:02



#       This is designed for my local dev VM,
#       and I will want to support 2 default "behaviors" - examples :
#
#       • http://192.168.123.123/example.com/dev/       <--- [1]
#       • http://192.168.123.123/any-folder/            <--- [1']
#       • http://dev.lan-123-123.io/                    <--- [2]
#       • http://example.com/                           <--- [2']
#
#       [1] : does NOT require editing one's OS Hosts file
#           (+ bonus : accessible on LAN if VM is bridged - e.g. quick demo for colleagues)
#           In this case, there's only the default "mapping" URL / Folder :
#
#           http://192.168.123.123/example.com/dev/     --->    /var/www/example.com/dev/
#
#       [2] : requires editing one's OS Hosts file
#           (ex: new line "192.168.123.123 lan-123-123.io" in C:\Windows\System32\drivers\etc\hosts)
#           Like in the example from the following link :
#           @see http://trac.nginx.org/nginx/ticket/314
#           I want it to dynamically "map" domain & subdomains to root directories in the following manner :
#
#           http://www.example.com/                     --->        /var/www/example.com/www/
#           http://www.lan-123-123.io/                  --->        /var/www/lan-123-123.io/www/
#           http://dev.lan-123-123.io/                  --->        /var/www/lan-123-123.io/dev/
#
#           Ideally, this exception should be handled (to avoid messing up the "subdomain = subdir" pattern) :
#
#           http://lan-123-123.io/                      --->        /var/www/lan-123-123.io/www/


#       test ok 2014/11/30 22:15:05
#       contents of /etc/nginx/sites-available/default :
server {
    
    listen 80 default_server;
    listen [::]:80 default_server;
    index index.php index.html index.htm;
    
    
    set $rootpath "/var/www";
    set $domain $host;
    set $case 0;
    
    if ($domain ~ "^(.[^.]*)\.([^.]+)$") {
        set $domain "$1.$2";
        set $rootpath "/var/www/${domain}/www";
        set $servername "${domain}";
        set $case 1;
    }
    
    if ($domain ~ "^(.*)\.(.[^.]*)\.([^.]+)$") {
        set $subdomain $1;
        set $domain "$2.$3";
        set $rootpath "/var/www/${domain}/${subdomain}";
        set $servername "${subdomain}.${domain}";
        set $case 2;
    }
    
    # debug ok 2014/11/30 22:04:48
#    add_header X-debugco "${case}";
#    add_header X-debugrp "${rootpath}";
#    add_header X-debugsn "${servername}";
    
    server_name $servername;
    access_log "/var/log/nginx/${servername}.access.log";
    error_log "/var/log/nginx/${servername}.error.log";
    root $rootpath;
    
    
    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
    }
    
}


server {
    
    listen 80;
    listen [::]:80;
    index index.php index.html index.htm;
    root /var/www;
    server_name ~^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(.*)$;
    
    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
    }
}


#       tested OK !
#       http://192.168.0.25/test/
#       http://subtest.lan-0-25.io/
#       http://dev.lan-0-25.io/
#       http://dev.lan-0-25.io/
#       http://lan-0-25.io/
#       http://www.lan-0-25.io/





#----------------------------------------------------------------------------
#       PHP admin Tools

#       Opcode status
#cd /path/to/wherever
wget https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php

#       Minimalist multi-DB Tool
#cd /path/to/wherever
wget http://downloads.sourceforge.net/adminer/adminer-4.1.0-en.php -O adminer.php


#----------------------------------------------------------------------------
#       Misc

apt-get install htop -y


