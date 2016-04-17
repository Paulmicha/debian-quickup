#!/bin/bash
# -*- coding: UTF8 -*-

##
#   LAMP server quick setup script
#   for local dev
#   Drupal & Symfony friendly
#   (to be run as root)
#   
#   Tested on Debian 8 "Jessie", 
#   @timestamp 2016/04/17 20:06:37
#   
#   @todo make a version of this script using the better performing setup :
#   apache2-mpm-worker + php-fpm
#   @see https://github.com/Paulmicha/debian-quickup/blob/master/LAMP/Apache%20Php-FPM%20Composer%20HHVM/Debian7_MariaDB_Php5.5_Composer_HHVM_Drush7.script.sh
#   
#   Install :
#   $ mkdir ~/custom_scripts
#   $ wget https://github.com/Paulmicha/debian-quickup/raw/master/LAMP/Debian8_LAMP.script.sh --quiet --no-check-certificate -O ~/custom_scripts/debian8_lamp_setup.sh
#   $ chmod +x ~/custom_scripts/debian8_lamp_setup.sh
#   
#   Use :
#   Edit values to your liking, then
#   $ ~/custom_scripts/debian8_lamp_setup.sh ThisFirstParamIsMySQLAdminPassword
#   
#   Sources :
#   https://abdussamad.com/archives/620-Debian-Linux:-Setting-the-timezone-and-synchronizing-time-with-NTP.html
#   http://support.ntp.org/bin/view/Servers/NTPPoolServers
#   http://www.mad-hacking.net/documentation/linux/applications/ntp/ntpclient.xml
#   https://github.com/facebook/hhvm/wiki/Prebuilt-Packages-on-Debian-8
#   http://markvaneijk.com/use-hhvm-to-speed-up-composer
#   http://stackoverflow.com/questions/3984824/sed-command-in-bash
#   http://serverfault.com/questions/551854/is-it-possible-to-auto-update-php-ini-via-a-bash-script
#   

#   Param 1 : MySQL admin user password
MYSQL_ADMIN_PASSWORD=${1}
if [ -z "${1}" ]; then
    MYSQL_ADMIN_PASSWORD="changeThisPassword"
fi


#----------------------------------------------------------------------------
#   LAMP stack

#   Apache
apt-get install apache2 -y
a2enmod rewrite

#   Apache tuning default config
cat > /etc/apache2/conf-available/custom-lan-dev.conf <<'EOF'
<VirtualHost *:80>
	<Directory "/var/www/html">
        AllowOverride All
    </Directory>
</VirtualHost>
EOF
a2enconf custom-lan-dev

#   MySQL
DEBIAN_FRONTEND='noninteractive' apt-get install mysql-server -y
echo "SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('${MYSQL_ADMIN_PASSWORD}')" | mysql --user=root
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ADMIN_PASSWORD}')" | mysql --user=root

#   PHP
apt-get install curl -y
apt-get install php5 php5-dev php5-cli php5-common php5-mysql php5-curl php-pear php5-gd php5-mcrypt -y
apt-get install php5-intl -y

#   Upload Progress
pecl install uploadprogress
echo -e "extension=uploadprogress.so" > /etc/php5/apache2/conf.d/50-uploadprogress.ini

#   UTF-8 for mbstring
echo -e "; Set mbstring defaults to UTF-8
mbstring.language=UTF-8
mbstring.internal_encoding=UTF-8
mbstring.detect_order=auto" > /etc/php5/apache2/conf.d/20-mbstring.ini

#   Main php.ini configuration : modif. with sed (NB: creates a backup on the 1st call)
#   @see http://stackoverflow.com/questions/3984824/sed-command-in-bash
#   @see http://serverfault.com/questions/551854/is-it-possible-to-auto-update-php-ini-via-a-bash-script
sed -e 's,memory_limit = 128M,memory_limit = 512M,g' -i.bak /etc/php5/apache2/php.ini
sed -e 's,max_execution_time = 30,max_execution_time = 0,g' -i /etc/php5/apache2/php.ini
sed -e 's,display_errors = Off,display_errors = On,g' -i /etc/php5/apache2/php.ini
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 128M,g' -i /etc/php5/apache2/php.ini
sed -e 's,max_input_time = 60,max_input_time = 120,g' -i /etc/php5/apache2/php.ini
sed -e 's,post_max_size = 8M,post_max_size = 130M,g' -i /etc/php5/apache2/php.ini
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i /etc/php5/apache2/php.ini

#   Opcode Cache
#   In Debian 8, installing packet "php5" results in Php 5.6.7-1 as of 2015/05/08 00:48:13
#   Opcache is bundled in PHP >= 5.5
#   → Allocate more memory for opcode cache (ex: 384M)
echo "opcache.memory_consumption=384" >> /etc/php5/mods-available/opcache.ini

#   Reload config
service apache2 reload

#   SQLite3
cd ~
apt-get install sqlite3 -y
apt-get install php5-sqlite -y

#   Image magik
#apt-get install imagemagick -y
#apt-get install php5-imagick -y

#   Restart Apache
service apache2 restart


#----------------------------------------------------------------------------
#   Composer

cd /usr/local/bin
curl -s http://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#   HHVM (to speed up Composer)
#   Install using pre-built HHVM package
#   @see http://markvaneijk.com/use-hhvm-to-speed-up-composer
#   @see https://github.com/facebook/hhvm/wiki/Prebuilt-Packages-on-Debian-8
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449
echo deb http://dl.hhvm.com/debian jessie main | tee /etc/apt/sources.list.d/hhvm.list
apt-get update
apt-get install hhvm -y

#   Bash alias
cd ~
echo "alias composer='hhvm /usr/local/bin/composer'" > '.bash_profile'

#   While we're at it...
echo "alias ls='ls --color=auto'
alias grep='grep --color=auto'" >> '.bash_profile'

#   Activate
source .bash_profile


#----------------------------------------------------------------------------
#   Server tools

#   Misc. utils
apt-get install unzip -y
apt-get install htop -y

#   CVS
#   Note : SVN untested as of 2015/05/07 22:32:40
#apt-get install subversion -y
apt-get install git-core -y

#   Drush 7
mkdir /usr/local/share/drush
cd /usr/local/share/drush
git clone https://github.com/drush-ops/drush.git -b master .
chmod u+x drush
ln -s /usr/local/share/drush/drush /usr/bin/drush
composer install


#   Tweak bash
cd ~
wget https://raw.github.com/drush-ops/drush/master/examples/example.bashrc
mv example.bashrc .drush_bashrc

echo 'if [ -f ~/.drush_bashrc ] ; then
  . ~/.drush_bashrc
fi' >> ~/.bash_profile

#   Activate bash tweak
source .bash_profile


#----------------------------------------------------------------------------
#   PHP admin Tools

#   Opcode cache status
#   (visualize memory allocated to opcode)
cd /var/www/html
wget https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php

#   Adminer
#   (Minimalist multi-DB Tool)
#   English-only, MySQL-only version
#   @see http://www.adminer.org/#download for other (and latest) versions
mkdir /var/www/html/adminer
wget https://www.adminer.org/static/download/4.2.4/adminer-4.2.4-en.php -O /var/www/html/adminer/index.php
wget https://raw.github.com/vrana/adminer/master/designs/nette/adminer.css -O /var/www/html/adminer/adminer.css


#----------------------------------------------------------------------------
#   Server time

#apt-get install ntpdate -y

#   The NTP Pool DNS system automatically picks time servers
#   which are geographically close for you, but if you want
#   to choose explicitly, there are sub-zones of pool.ntp.org.
#   @see http://support.ntp.org/bin/view/Servers/NTPPoolServers
#ntpdate pool.ntp.org

#   Make the changes stick : set the hardware clock
#hwclock --systohc

#   Ensure that your server’s clock is always accurate
#   → install the ntp daemon
#   Note : seems to already be installed
#apt-get install ntp -y



