#!/bin/bash
# -*- coding: UTF8 -*-

##
#   LAMP server quick setup shell script, for local dev purposes (run as su or root),
#   tested on Debian 7.4 "Wheezy", Drupal 8 & Symfony friendly
#   
#   (as of 2014/03/20 01:58:58, only tested step by step manually)
#   
#   Sources :
#   http://www.dotdeb.org/instructions/
#   http://markvaneijk.com/use-hhvm-to-speed-up-composer
#   https://github.com/facebook/hhvm/wiki/Prebuilt-Packages-on-Debian-7
#   http://stackoverflow.com/questions/3984824/sed-command-in-bash
#   http://serverfault.com/questions/551854/is-it-possible-to-auto-update-php-ini-via-a-bash-script
#   http://www.linuxfromscratch.org/blfs/view/svn/postlfs/profile.html
#   
#   @author Paulmicha
#   @timestamp 2014/03/19 23:18:34
#   

VERSION="1.0-dev"
SCRIPT_NAME="$(basename ${0})"


##
#   Usage info
#
function usage {
  echo "Debian 7.4 'Wheezy' quickup v${VERSION}
Drupal 8 & Symfony friendly LAMP server quick setup shell script for local dev
Usage :
  ./${SCRIPT_NAME} [ mysql_root_user_password ]
"
  exit 1
}

#       Param 1 : MySQL admin user password
MYSQL_ADMIN_PASSWORD=${1}
if [ -z "${1}" ]; then
    MYSQL_ADMIN_PASSWORD="changeThisPassword"
fi


#----------------------------------------------------------------------------
#       LAMP stack

#       Apache
apt-get install apache2 -y
a2enmod rewrite

#       Apache tuning default config
#       (just changing "AllowOverride" -> "All" for /var/www/)
mv /etc/apache2/sites-available/default /etc/apache2/sites-available/default.bak
echo -n '<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory /var/www/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Order allow,deny
		allow from all
	</Directory>
	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
	<Directory "/usr/lib/cgi-bin">
		AllowOverride None
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>
	ErrorLog ${APACHE_LOG_DIR}/error.log
	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/default

#       MySQL
DEBIAN_FRONTEND='noninteractive' apt-get install mysql-server apg -y
echo "SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('${MYSQL_ADMIN_PASSWORD}')" | mysql --user=root
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ADMIN_PASSWORD}')" | mysql --user=root

#       MySQL tuning
echo '# Base MySQL optimisations.
[mysqld]
# Enable binary log for point in time recovery.
# see : https://dev.mysql.com/doc/refman/5.1/en/point-in-time-recovery.html
log_bin = /var/log/mysql/mysql-bin.log
sync_binlog = 1

# Limit binary log size to prevent databases lock ups at binary log rotation.
# see : http://www.mysqlperformanceblog.com/2012/05/24/binary-log-file-size-matters/
max_binlog_size = 50M

# Enable slow query log for Query debuging:
log_slow_queries = /var/log/mysql/mysql-slow.log
long_query_time = 5

# Uncomment this to log unoptimized queries.
#log-queries-not-using-indexes' \
    > '/etc/mysql/conf.d/base-optimisations.cnf'

#       Restart mysql
/etc/init.d/mysql restart

#       PHP
apt-get install curl -y
#       Note : "--force-yes -y" untested, seems required
apt-get install php5 php5-dev php5-cli php5-common php5-mysql php5-curl php-pear php5-gd php5-mcrypt php5-xdebug --force-yes -y
apt-get install php5-intl --force-yes -y
pecl install uploadprogress
echo -e "extension=uploadprogress.so" > /etc/php5/apache2/conf.d/uploadprogress.ini

#       Not sure : dir missing ?
mkdir /etc/php5/conf.d

#       UTF-8 for mbstring
echo '; Set mbstring defaults to UTF-8
mbstring.language=UTF-8
mbstring.internal_encoding=UTF-8
; mbstring.http_input=UTF-8
; mbstring.http_output=UTF-8
mbstring.detect_order=auto' \
    > '/etc/php5/conf.d/mbstring.ini'

#       XDebug remote setup
#       Note : if using NetBeans, menu Tools > Options > PHP > tab "Debugging" > uncheck 'stop at first line'
#       And don't forget to change "192.168.*.*" with the IP of the machine requesting the debug
echo '; Enable Remote XDebug
; zend_extension="/usr/lib/php5/20121212/xdebug.so"
xdebug.remote_enable=1
xdebug.remote_handler=dbgp
xdebug.remote_mode=req
xdebug.remote_host="192.168.*.*"
xdebug.remote_port=9000' \
    > '/etc/php5/conf.d/xdebug.ini'

#       Main php.ini configuration : modif. with sed (NB: creates a backup on the 1st call)
#       @see http://stackoverflow.com/questions/3984824/sed-command-in-bash
#       @see http://serverfault.com/questions/551854/is-it-possible-to-auto-update-php-ini-via-a-bash-script
sed -e 's,;default_charset = "UTF-8",default_charset = "UTF-8",g' -i.bak /etc/php5/apache2/php.ini
sed -e 's,max_input_time = 60,max_input_time = 120,g' -i /etc/php5/apache2/php.ini
sed -e 's,memory_limit = 128M,memory_limit = 256M,g' -i /etc/php5/apache2/php.ini
sed -e 's,display_errors = Off,display_errors = On,g' -i /etc/php5/apache2/php.ini
sed -e 's,post_max_size = 8M,post_max_size = 130M,g' -i /etc/php5/apache2/php.ini
sed -e 's,upload_max_filesize = 2M,upload_max_filesize = 128M,g' -i /etc/php5/apache2/php.ini
sed -e 's,;date.timezone =,date.timezone = '$(command cat /etc/timezone)',g' -i /etc/php5/apache2/php.ini

#       Reload config
service apache2 reload

#       SQLite3
cd ~
apt-get install sqlite3 -y
apt-get install php5-sqlite -y

#       Image magik
apt-get install imagemagick -y
apt-get install php5-imagick -y

#       Restart Apache
service apache2 restart



#----------------------------------------------------------------------------
#       Composer


cd /usr/local/bin
curl -s http://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#       Install pre-built HHVM packge to speed up Composer
#       (update 2014/03/21 00:16:01)
#       @see http://markvaneijk.com/use-hhvm-to-speed-up-composer
#       @see https://github.com/facebook/hhvm/wiki/Prebuilt-Packages-on-Debian-7
wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | apt-key add -
echo deb http://dl.hhvm.com/debian wheezy main | tee /etc/apt/sources.list.d/hhvm.list
apt-get update
apt-get install hhvm

#       Bash alias
#       update 2014/03/21 01:04:21 - choose between .bash_profile OR .bashrc (see below - Drush part)
cd ~
#echo "alias composer='hhvm /usr/local/bin/composer'" > '.bashrc'
echo "alias composer='hhvm /usr/local/bin/composer'" > '.bash_profile'

#       While we're at it...
#echo "alias ls='ls --color=auto'
#alias grep='grep --color=auto'" >> '.bashrc'
echo "alias ls='ls --color=auto'
alias grep='grep --color=auto'" >> '.bash_profile'

#       Activate
#source .bashrc
source .bash_profile



#----------------------------------------------------------------------------
#       Server tools

#       Utils
apt-get install unzip -y
apt-get install htop -y

#       Versionning
#       Note : SVN still version 1.6 on wheezy by default...
#       @see https://github.com/Paulmicha/debian-quickup/blob/master/Debian-7-Wheezy-SVN-1.8.sh
#apt-get install subversion -y
apt-get install git-core -y

#       Drush 7.x (dev) which is required for Drupal 8
#       Error - Composer installation method fails :
#       "-bash: drush: command not found"
#composer global require drush/drush:dev-master

#       Drush 7 Alternative install : manual
#       test ok 2014/03/20 01:51:35
mkdir /usr/local/share/drush
cd /usr/local/share/drush
git clone https://github.com/drush-ops/drush.git -b master .
chmod u+x drush
ln -s /usr/local/share/drush/drush /usr/bin/drush
composer install


#       Tweak bash
cd ~
wget https://raw.github.com/drush-ops/drush/master/examples/example.bashrc
mv example.bashrc .drush_bashrc

#echo -n 'if [ -f ~/.drush_bashrc ] ; then
#  . ~/.drush_bashrc
#fi' > ~/.bash_profile

echo 'if [ -f ~/.drush_bashrc ] ; then
  . ~/.drush_bashrc
fi' >> ~/.bash_profile

    




