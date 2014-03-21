#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Local Server quick setup script (to be run as root),
#   for local dev :
#       • Apache - 2.2.22 - mpm worker
#       • Php - 5.5 Dotdeb - fpm (fastcgi)
#       • MariaDB - 10.0.0.9
#       • Composer
#       • HHVM - Facebook's "HipHop Php" JIT compiler + bash alias for Composer
#       • Drush 7 (for Drupal 8) + bash alias
#   
#   Postponed for now, but might add it in here too :
#       • Node + Grunt
#       • Ruby + Gem + Compass
#       • https://github.com/BBC-News/wraith
#   
#   Tested on Debian 7.4 "Wheezy" (fresh install inside VirtualBox) on 2014/03/21 05:46:57
#   
#   Sources :
#   http://www.dotdeb.org/instructions/
#   http://www.janoszen.com/2013/04/29/setting-up-apache-with-php-fpm/
#   http://howto.biapy.com/fr/debian-gnu-linux/serveurs/php/installer-php-fpm-sur-debian
#   https://downloads.mariadb.org
#   http://stackoverflow.com/questions/3984824/sed-command-in-bash
#   http://serverfault.com/questions/551854/is-it-possible-to-auto-update-php-ini-via-a-bash-script
#   http://markvaneijk.com/use-hhvm-to-speed-up-composer
#   https://github.com/facebook/hhvm/wiki/Prebuilt-Packages-on-Debian-7
#   
#   @timestamp 2014/03/21 03:41:56
#   


#----------------------------------------------------------------------------
#       Apache

apt-get install apache2-mpm-worker -y
a2enmod rewrite



#----------------------------------------------------------------------------
#       Php 5.5 from Dotdeb

cd ~
add-apt-repository 'deb http://packages.dotdeb.org wheezy all'
add-apt-repository 'deb http://packages.dotdeb.org wheezy-php55 all'
wget http://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg

aptitude update
aptitude install php5-fpm php5 -y


#       Apache FastCGI PHP support
#       NB: as of 2014/03/21 04:21:32, need to add "non-free" sources
#       otherwise I got the error : "libapache2-mod-fastcgi is not available"
sed -e 's,debian.org/debian/ wheezy main,debian.org/debian/ wheezy main non-free,g' -i.bak /etc/apt/sources.list
sed -e 's,debian.org/ wheezy/updates main,debian.org/ wheezy/updates main non-free,g' -i /etc/apt/sources.list
sed -e 's,debian.org/debian/ wheezy-updates main,debian.org/debian/ wheezy-updates main non-free,g' -i /etc/apt/sources.list

aptitude update
aptitude install libapache2-mod-fastcgi -y

#       Using handy config from http://howto.biapy.com/fr/debian-gnu-linux/serveurs/php/installer-php-fpm-sur-debian
#       (see below for contents)
wget 'https://raw.github.com/biapy/howto.biapy.com/master/apache2/php-fpm/php5-fpm.load' --quiet --no-check-certificate --output-document='/etc/apache2/mods-available/php5-fpm.load'
wget 'https://raw.github.com/biapy/howto.biapy.com/master/apache2/php-fpm/php5-fpm.conf' --quiet --no-check-certificate --output-document='/etc/apache2/mods-available/php5-fpm.conf'

#       Alternative to the above (hardcoded)
#echo -n '# PHP-FPM configuration.
# dummy file, see /etc/apache2/mods-available/php5-fpm.conf' > '/etc/apache2/mods-available/php5-fpm.load'
#echo -n '# PHP-FPM configuration
#<IfModule mod_fastcgi.c>
#  Alias /php5.fastcgi /var/lib/apache2/fastcgi/php5.fastcgi
#  AddHandler php-script .php
#  FastCGIExternalServer /var/lib/apache2/fastcgi/php5.fastcgi -socket /var/run/php5-fpm.sock -idle-timeout 610
#  Action php-script /php5.fastcgi virtual

  # Forbid access to the fastcgi handler.
#  <Directory /var/lib/apache2/fastcgi>
#    <Files php5.fastcgi>
#      Order deny,allow
#      Allow from all
#    </Files>
#  </Directory>

  # FPM status page.
#  <Location /php-fpm-status>
#    SetHandler php-script
#    Order deny,allow
#    Deny from all
#    Allow from 127.0.0.1 ::1
#  </Location>

  # FPM ping page.
#  <Location /php-fpm-ping>
#    SetHandler php-script
#    Order deny,allow
#    Deny from all
#    Allow from 127.0.0.1 ::1
#  </Location>
#</IfModule>' > '/etc/apache2/mods-available/php5-fpm.conf'


#       This results in : "Module php5 does not exist"
#       -> unneeded, left here for achive
#a2dismod php5

#       Enable FPM config & restart Apache
a2enmod php5-fpm fastcgi actions
service apache2 restart



#----------------------------------------------------------------------------
#       Php extensions & config

#       Cli
apt-get install php5-cli -y

#       Test :
php -v
#       Result (as of 2014/03/21 04:49:49) :
#           PHP 5.5.10-1~dotdeb.1 (cli) (built: Mar  6 2014 18:55:59)
#           Copyright (c) 1997-2014 The PHP Group
#           Zend Engine v2.5.0, Copyright (c) 1998-2014 Zend Technologies
#               with Zend OPcache v7.0.3, Copyright (c) 1999-2014, by Zend Technologies

#       Curl, gd, mcrypt
apt-get install curl -y
apt-get install php5-curl -y
apt-get install php5-gd -y
apt-get install php5-mcrypt -y

#       SQLite3
apt-get install sqlite3 -y
apt-get install php5-sqlite -y

#       Image magik
apt-get install imagemagick -y
apt-get install php5-imagick -y

#       Xdebug
apt-get install php5-xdebug -y

#       Main php.ini configuration : modif. with sed (NB: creates a backup on the 1st call)
#       @see http://stackoverflow.com/questions/3984824/sed-command-in-bash
#       @see http://serverfault.com/questions/551854/is-it-possible-to-auto-update-php-ini-via-a-bash-script
sed -e 's,;default_charset = "UTF-8",default_charset = "UTF-8",g' -i.bak /etc/php5/fpm/php.ini
sed -e 's,max_input_time = 60,max_input_time = 120,g' -i /etc/php5/fpm/php.ini
sed -e 's,memory_limit = 128M,memory_limit = 256M,g' -i /etc/php5/fpm/php.ini
sed -e 's,display_errors = Off,display_errors = On,g' -i /etc/php5/fpm/php.ini
sed -e 's,post_max_size = 8M,post_max_size = 130M,g' -i /etc/php5/fpm/php.ini
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 128M,g' -i /etc/php5/fpm/php.ini
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i /etc/php5/fpm/php.ini

#       Reload config
service 'php5-fpm' 'restart'



#----------------------------------------------------------------------------
#       MariaDB 10.x (RC as of 2014/03/21 04:31:49)

#       NB: repo mirror to choose from https://downloads.mariadb.org/mariadb/repositories
apt-get install python-software-properties -y
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
add-apt-repository 'deb http://mirror.jmu.edu/pub/mariadb/repo/10.0/debian wheezy main'
apt-get update

#       NB : this will popup screen for entering MariaDB root password
apt-get install mariadb-server -y

#       PHP Driver (mysql)
apt-get install php5-mysql



#----------------------------------------------------------------------------
#       Composer

cd /usr/local/bin
curl -s http://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#       Facebook's "HipHop Php" HHVM
#       (JIT compiler, mainly to speed up Composer)
#       @see http://markvaneijk.com/use-hhvm-to-speed-up-composer
#       @see https://github.com/facebook/hhvm/wiki/Prebuilt-Packages-on-Debian-7
cd ~
wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | apt-key add -
echo deb http://dl.hhvm.com/debian wheezy main | tee /etc/apt/sources.list.d/hhvm.list
apt-get update
apt-get install hhvm -y

#       Bash alias
echo "alias composer='hhvm /usr/local/bin/composer'" > '.bash_profile'

#       While we're at it...
echo "alias ls='ls --color=auto'
alias grep='grep --color=auto'" >> '.bash_profile'

#       Debug - manual check - ok 2014/03/21 06:16:03
#nano .bash_profile

#       Activate
source .bash_profile



#----------------------------------------------------------------------------
#       Server tools

#       Utils
apt-get install htop -y
apt-get install unzip -y

#       Git
apt-get install git-core -y

#       Drush (master - 7.x-dev)
#       Manual installation
mkdir /usr/local/share/drush
cd /usr/local/share/drush
git clone https://github.com/drush-ops/drush.git -b master .
chmod u+x drush
ln -s /usr/local/share/drush/drush /usr/bin/drush
composer install

#       Drush bash alias
cd ~
wget 'https://raw.github.com/drush-ops/drush/master/examples/example.bashrc' --quiet --no-check-certificate --output-document='.drush_bashrc'

echo 'if [ -f ~/.drush_bashrc ] ; then
  . ~/.drush_bashrc
fi' >> .bash_profile

#       Debug - manual check - ok 2014/03/21 06:16:03
#nano ~/.bash_profile

#       Activate
source .bash_profile




