#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Redmine setup
#   Debian 7 ("Wheezy")
#
#   @timestamp 2014/08/26 19:43:03
#   @failed 2014/08/26 22:11:50 - giving up, archived
#   
#   Sources :
#   http://martin-denizet.com/install-redmine-2-5-x-with-git-and-subversion-on-debian-with-apache2-rvm-and-passenger/
#

REDMINE_USERNAME="my_redmine_user"
REDMINE_PASSWORD="my_redmine_pass"
DB_NAME="my_database_name"
DB_USERNAME="my_database_user"
DB_PASSWORD="my_database_password"
DB_ADMIN_USERNAME="my_database_admin_user"
DB_ADMIN_PASSWORD="my_database_admin_password"



#--------------------------------------------
#   Packages dependencies


apt-get update

# Dependencies
# NB: this will prompt for mysql root passwd
apt-get install curl gawk g++ gcc make libc6-dev libreadline6-dev zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev git subversion imagemagick libmagickwand-dev mysql-server libmysqlclient-dev apache2 apache2-threaded-dev libcurl4-gnutls-dev apache2 libapache2-svn libapache-dbi-perl libapache2-mod-perl2 libdbd-mysql-perl libauthen-simple-ldap-perl openssl -y



#--------------------------------------------
#   DB setup


echo "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USERNAME'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
FLUSH PRIVILEGES;" | mysql -u $DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD



#--------------------------------------------
#   Ruby + Redmine


curl -sSL https://get.rvm.io | bash -s stable --ruby=2.0.0
cd /opt/
mkdir redmine
cd redmine/
svn co http://svn.redmine.org/redmine/branches/2.5-stable current
cd current/
mkdir -p tmp tmp/pdf public/plugin_assets
chown -R www-data:www-data files log tmp public/plugin_assets
chmod -R 755 files log tmp public/plugin_assets
mkdir -p /opt/redmine/repos/svn /opt/redmine/repos/git
chown -R www-data:www-data /opt/redmine/repos

# Configuration
cp config/configuration.yml.example config/configuration.yml
cp config/database.yml.example config/database.yml
nano config/database.yml
#   -> edit "production" credentials, then save (ctrl + O)

# Creating user for Redmine app
useradd $REDMINE_USERNAME
echo $REDMINE_PASSWORD | passwd $REDMINE_USERNAME --stdin

# Init (NOT as root)
su - $REDMINE_USERNAME
cd /opt/redmine/current
bundle install --without development test
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake redmine:load_default_data



#--------------------------------------------
#   Webserver (Apache)


# back to root
su

apt-get install apache2 apache2-threaded-dev libcurl4-gnutls-dev apache2 libapache2-svn libapache-dbi-perl libapache2-mod-perl2 libdbd-mysql-perl libauthen-simple-ldap-perl openssl -y
a2enmod ssl
a2enmod perl
a2enmod dav
a2enmod dav_svn
a2enmod dav_fs
a2enmod rewrite
a2enmod headers
service apache2 restart

# Passenger (Apache-Ruby "bridge")
gem install passenger
passenger-install-apache2-module

# Copy the lines indicated at the end of the proces in :
nano /etc/apache2/conf.d/passenger.conf
#   Ex :
#LoadModule passenger_module /usr/local/rvm/gems/ruby-2.0.0-p481/gems/passenger-4.0.49/buildout/apache2/mod_passenger.so
#<IfModule mod_passenger.c>
#  PassengerRoot /usr/local/rvm/gems/ruby-2.0.0-p481/gems/passenger-4.0.49
#  PassengerDefaultRuby /usr/local/rvm/gems/ruby-2.0.0-p481/wrappers/ruby
#</IfModule>

service apache2 restart



#--------------------------------------------
#   SSL Certificate


# Self-signed
mkdir /etc/apache2/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/redmine.key -out /etc/apache2/ssl/redmine.crt

#   TODO 2014/08/26 21:38:28 - finish this
#   (meanwhile : manual replace)
cd /etc/apache2/sites-available
wget https://gist.githubusercontent.com/martin-denizet/11080033/raw/redmine.vhost
wget https://gist.githubusercontent.com/martin-denizet/11080033/raw/redmine-redirect.vhost



#--------------------------------------------
#   Enable


#   Fails :
#   Syntax error on line 81 of /etc/apache2/sites-enabled/redmine.vhost:
#   Can’t locate Apache2/Redmine.pm in @INC (…) at (eval 2) line 2.\n
#   Action ‘configtest’ failed.
#   The Apache error log may have more information.
#   failed!
a2dissite default
a2ensite redmine.vhost
a2ensite redmine-redirect.vhost
service apache2 restart


