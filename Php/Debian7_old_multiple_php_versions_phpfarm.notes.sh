#!/bin/bash
# -*- coding: UTF8 -*-

##
#   FAILS 2015/03/11 18:07:33 :
#   Php files are not interpreted by FCGI (plain text)
#   
#   Install old and/or multiple versions of Php
#   Tested on Debian 7 "Wheezy"
#   
#   Sources :
#   http://cweiske.de/tagebuch/Introducing%20phpfarm.htm
#   http://sourceforge.net/p/phpfarm/wiki/Compilation%20errors/
#       → https://bugs.php.net/bug.php?id=54736
#       → https://github.com/omega8cc/boa/blob/master/aegir/patches/disable_SSLv2_for_openssl_1_0_0.patch
#   http://cweiske.de/tagebuch/Running%20Apache%20with%20a%20dozen%20PHP%20versions.htm
#   http://serverfault.com/questions/599707/e-package-libapache2-mod-fastcgi-has-no-installation-candidate-debian-ser
#   
#   Archived, failed tests :
#   https://www.howtoforge.com/building-php-5.4-from-source-on-debian-squeeze
#       → https://bugs.php.net/bug.php?id=33685&edit=1
#   
#   @timestamp 2015/03/11 13:29:41
#


#----------------------------------------------------------------------------
#       Prerequisites
#       @todo re-test on bare vm (current test done with build-related packages installed)

apt-get install git-core -y



#----------------------------------------------------------------------------
#       Compiling Php 5.2.13
#       (adapt Php version numbers below according to your needs)
#       Warning : php sources versions 5.2.x requires patch
#       @see http://sourceforge.net/p/phpfarm/wiki/Compilation%20errors/


#       Get phpfarm
cd /opt
git clone git://git.code.sf.net/p/phpfarm/code phpfarm

#       Attempt to install (will fail, but let it download sources)
#       Instead, you may want to download sources manually in /opt/phpfarm/src/php-5.2.13/ for patching, see below
cd /opt/phpfarm/src
./compile 5.2.13

#       Apply Patch
#       Note : also copied patch file in this repo for backup
#       @see ./disable_SSLv2_for_openssl_1_0_0.patch
cd /opt/phpfarm/src/php-5.2.13/
wget https://github.com/omega8cc/boa/raw/master/aegir/patches/disable_SSLv2_for_openssl_1_0_0.patch --quiet --no-check-certificate
patch ext/openssl/xp_ssl.c < disable_SSLv2_for_openssl_1_0_0.patch

#       (Re-)compile
cd /opt/phpfarm/src
./compile 5.2.13

#       Result :
#Build complete.
#Don't forget to run 'make test'.
#Installing PHP SAPI module:       cgi
#Installing PHP CGI binary: /opt/phpfarm/inst/php-5.2.13/bin/
#Installing PHP CLI binary:        /opt/phpfarm/inst/php-5.2.13/bin/
#Installing PHP CLI man page:      /opt/phpfarm/inst/php-5.2.13/man/man1/
#Installing build environment:     /opt/phpfarm/inst/php-5.2.13/lib/php/build/
#Installing header files:          /opt/phpfarm/inst/php-5.2.13/include/php/
#Installing helper programs:       /opt/phpfarm/inst/php-5.2.13/bin/
#  program: phpize
#  program: php-config
#Installing man pages:             /opt/phpfarm/inst/php-5.2.13/man/man1/
#  page: phpize.1
#  page: php-config.1
#Installing PDO headers:          /opt/phpfarm/inst/php-5.2.13/include/php/ext/pdo/



#----------------------------------------------------------------------------
#       Apache configuration
#       @see http://cweiske.de/tagebuch/Running%20Apache%20with%20a%20dozen%20PHP%20versions.htm

#       Install Apache "mpm-worker" version + mod-fastcgi
#       Note : needs "contrib non-free" in /etc/apt/sources.list
#       @see http://serverfault.com/questions/599707/e-package-libapache2-mod-fastcgi-has-no-installation-candidate-debian-ser
aptitude install libapache2-mod-fastcgi apache2-mpm-worker apache2-suexec

#       Enable mods
a2enmod actions fastcgi suexec

#       Prepare FastCGI servers
#       Note : need one line per Php version installed
#       (these lines : "FastCgiServer /var/www/cgi-bin/php-cgi-5.2.13")
echo -n "FastCgiServer /var/www/cgi-bin/php-cgi-5.2.13
ScriptAlias /cgi-bin-php/ /var/www/cgi-bin/
" > /etc/apache2/conf.d/php-cgisetup.conf

#       Php-CGI setup
#       (To do for each Php version installed
#       + adapt Php version numbers below according to your needs)
mkdir /var/www/cgi-bin
echo -n '#!/bin/sh
PHPRC="/etc/php5/cgi/5.2.13/"
export PHPRC
 
PHP_FCGI_CHILDREN=3
export PHP_FCGI_CHILDREN
 
PHP_FCGI_MAX_REQUESTS=5000
export PHP_FCGI_MAX_REQUESTS
 
exec /opt/phpfarm/inst/bin/php-cgi-5.2.13
' > /var/www/cgi-bin/php-cgi-5.2.13
chmod +x /var/www/cgi-bin/php-cgi-5.2.13

#       WARNING :
#       On Php 5.2 and lower, the --enable-fastcgi configure flag is required :
nano /opt/phpfarm/inst/bin/php-config-5.2.13
#       -> Edit line 18 to obtain :
#configure_options=" '--prefix=/opt/phpfarm/inst/php-5.2.13' '--exec-prefix=/opt/phpfarm/inst/php-5.2.13' '--enable-debug' '--disable-short-tags' '--without-pear' '--enable-bcmath' '--enable-calendar' '--enable-exif' '--enable-ftp' '--enable-mbstring' '--enable-pcntl' '--enable-soap' '--enable-sockets' '--enable-sqlite-utf8' '--enable-wddx' '--enable-zip' '--with-openssl' '--with-zlib' '--with-gettext' '--enable-fastcgi'"

#       Restart to apply config
service apache2 restart



#----------------------------------------------------------------------------
#       VHosts


#       Example
#       (adapt hostname, path, Php version numbers, etc.)
echo -n '<VirtualHost *:80>
	<Directory "/var/www/aproject/www">
        AllowOverride All
        AddHandler php-cgi .php
        Action php-cgi /cgi-bin-php/php-cgi-5.2.13
        <FilesMatch "\.php$">
            SetHandler php-cgi
        </FilesMatch>
    </Directory>
</VirtualHost>
' > /etc/apache2/sites-available/aproject

#       Enable vhost
#       Note - if needed, debug config with $ apachectl configtest
a2ensite aproject
service apache2 reload

#       Test failed
#       http://i0.kym-cdn.com/photos/images/original/000/000/578/1234931504682.jpg ...
echo -n "<?php phpinfo();" > /var/www/aproject/www/index.php
chown $USER:www-data /var/www/aproject/www/index.php
chmod 640 /var/www/aproject/www/index.php


