#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Redmine setup
#   Debian 7 ("Wheezy")
#
#   @timestamp 2014/08/27 19:09:56 - tested ok from barebones Debian install
#   
#   Sources :
#   http://martin-denizet.com/install-redmine-2-5-x-with-git-and-subversion-on-debian-with-apache2-rvm-and-passenger/
#

REDMINE_DOMAIN="redmine.domain.com"
REDMINE_DOMAIN_ADMIN="admin@domain.com"
DB_NAME="redmine"
DB_USERNAME="redmine"
DB_PASSWORD="change_this_password"
DB_ADMIN_USERNAME="root"
DB_ADMIN_PASSWORD="my_database_admin_password"



#--------------------------------------------
#   Packages dependencies


apt-get update

# Dependencies
# NB: this will prompt for mysql root passwd
# @todo non-interactive version
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

# Init (NOT as root)
#su - www-data
# update 2014/08/27 16:44:40 - test as root anyways
# NOTE : I had to reboot here, as I had the error bundle : command not found - disappeared after reboot
cd /opt/redmine/current
bundle install --without development test
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake redmine:load_default_data



#--------------------------------------------
#   Webserver (Apache)


# back to root
# update 2014/08/27 16:54:56 - tested as root anyways
#su

apt-get install apache2 apache2-threaded-dev libcurl4-gnutls-dev apache2 libapache2-svn libapache-dbi-perl libapache2-mod-perl2 libdbd-mysql-perl libauthen-simple-ldap-perl openssl -y
a2enmod ssl
a2enmod perl
a2enmod dav
a2enmod dav_svn
a2enmod dav_fs
a2enmod rewrite
a2enmod headers
#service apache2 restart

# Passenger (Apache-Ruby "bridge")
gem install passenger
passenger-install-apache2-module

# Copy the lines indicated at the end of the proces in :
nano /etc/apache2/conf.d/passenger.conf
#   Ex :
#LoadModule passenger_module /usr/local/rvm/gems/ruby-2.0.0-p481/gems/passenger-4.0.50/buildout/apache2/mod_passenger.so
#<IfModule mod_passenger.c>
#  PassengerRoot /usr/local/rvm/gems/ruby-2.0.0-p481/gems/passenger-4.0.50
#  PassengerDefaultRuby /usr/local/rvm/gems/ruby-2.0.0-p481/wrappers/ruby
#</IfModule>


# Load the Redmine.pm library for Repository authentication
ln -s /opt/redmine/current/extra/svn/Redmine.pm /usr/lib/perl5/Apache2/

#service apache2 restart



#--------------------------------------------
#   VHost + SSL


# Self-signed certificate
mkdir /etc/apache2/ssl
# Note : this will prompt for details (country, company name, email, etc.)
# @todo : test free https://www.startssl.com/ certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/redmine.key -out /etc/apache2/ssl/redmine.crt

cd /etc/apache2/sites-available

#   (archive : manual replace)
#wget https://gist.githubusercontent.com/martin-denizet/11080033/raw/redmine.vhost
#wget https://gist.githubusercontent.com/martin-denizet/11080033/raw/redmine-redirect.vhost

echo -n "NameVirtualHost *:443
ServerName $REDMINE_DOMAIN

<VirtualHost *:443>
    ServerAdmin $REDMINE_DOMAIN_ADMIN
    ServerName $REDMINE_DOMAIN:443
    
    # Enable SSL with Perfect Forward Secrecy
    SSLEngine on
    SSLProtocol +TLSv1.2 +TLSv1.1 +TLSv1
    SSLCompression off
    SSLHonorCipherOrder on
    SSLCipherSuite \"ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-RC4-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:RC4-SHA:AES256-GCM-SHA384:AES256-SHA256:CAMELLIA256-SHA:ECDHE-RSA-AES128-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA:CAMELLIA128-SHA\"
    SSLCertificateFile /etc/apache2/ssl/redmine.crt
    SSLCertificateKeyFile /etc/apache2/ssl/redmine.key
    
    <IfModule mod_header.c>
        ## Enable Strict Transport: http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
        Header add Strict-Transport-Security \"max-age=15768000\"
    </IfModule>
    
    ## SSL Stapling, more at: https://www.insecure.ws/2013/10/11/ssltls-configuration-for-apache-mod_ssl/
    # SSLUseStapling on
    # SSLStaplingResponderTimeout 5
    # SSLStaplingReturnResponderErrors off
    # SSLStaplingCache shmcb:/var/run/ocsp(128000)
    
    DocumentRoot /opt/redmine/current/public/
    
    ## Passenger Configuration
    ## Details at http://www.modrails.com/documentation/Users%20guide%20Apache.html
    
    PassengerMinInstances 6
    PassengerMaxPoolSize 20
    RailsBaseURI /
    PassengerAppRoot /opt/redmine/current
    
    # Speeds up spawn time tremendously -- if your app is compatible. 
    # RMagick seems to be incompatible with smart spawning
    RailsSpawnMethod smart
    
    # Keep the application instances alive longer. Default is 300 (seconds)
    PassengerPoolIdleTime 1000
    
    # Keep the spawners alive, which speeds up spawning a new Application
    # listener after a period of inactivity at the expense of memory.
    RailsAppSpawnerIdleTime 3600
    
    # Additionally keep a copy of the Rails framework in memory. If you're 
    # using multiple apps on the same version of Rails, this will speed up
    # the creation of new RailsAppSpawners. This isn't necessary if you're
    # only running one or 2 applications, or if your applications use
    # different versions of Rails.
    PassengerMaxPreloaderIdleTime 0
    
    # Just in case you're leaking memory, restart a listener 
    # after processing 5000 requests
    PassengerMaxRequests 5000
    
    # only check for restart.txt et al up to once every 5 seconds, 
    # instead of once per processed request
    PassengerStatThrottleRate 5
    
    # If user switching support is enabled, then Phusion Passenger will by default run the web application as the owner if the file config/environment.rb (for Rails apps) or config.ru (for Rack apps). This option allows you to override that behavior and explicitly set a user to run the web application as, regardless of the ownership of environment.rb/config.ru.
    PassengerUser www-data
    PassengerGroup www-data
    
    # By default, Phusion Passenger does not start any application instances until said web application is first accessed. The result is that the first visitor of said web application might experience a small delay as Phusion Passenger is starting the web application on demand. If that is undesirable, then this directive can be used to pre-started application instances during Apache startup.
    PassengerPreStart https://localhost
    
    
    <Directory /opt/redmine/current/public/>
        Options Indexes FollowSymLinks -MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>
    
    
    #/svn location for users
    PerlLoadModule Apache2::Redmine
    
    <Location /svn>
        
        DAV svn
        SVNParentPath \"/opt/redmine/repos/svn\"
        Order deny,allow
        Deny from all
        Satisfy any

        PerlAccessHandler Apache2::Authn::Redmine::access_handler
        PerlAuthenHandler Apache2::Authn::Redmine::authen_handler

        AuthType Basic
        AuthName \"redmine SVN Repository\" 

        #read-only access    
        <Limit GET PROPFIND OPTIONS REPORT>
            Require valid-user
            Allow from 127.0.1.1
            Satisfy any
        </Limit>
        # write access
        <LimitExcept GET PROPFIND OPTIONS REPORT>
            Require valid-user
        </LimitExcept>

        ## for mysql
        RedmineDSN \"DBI:mysql:database=redmine;host=localhost\" 
        RedmineDbUser \"redmine\"
        RedmineDbPass \"my_password\"
        
        #Possible security tweaks:
        #Order deny,allow
        #Allow from localhost
        #Allow from my_domain.com
        #Deny from all
    </Location>
    
    # /git location for users
    # Git Smart HTTP configuration
    #From the Remine.pm patch file for git-smart-http: 
    SetEnv GIT_PROJECT_ROOT /opt/redmine/repos/git/
    SetEnv GIT_HTTP_EXPORT_ALL
    
    ScriptAlias /git/ /usr/lib/git-core/git-http-backend/
    
    PerlLoadModule Apache2::Redmine
    
    <Location /git>
        Order allow,deny
        ## Sample configuration
        # Allow from 192.168.15.0/24 #Retrict Git access to local network
        Satisfy all

        AuthType Basic
        AuthName \"git repositories\" 
        Require valid-user

        PerlAccessHandler Apache2::Authn::Redmine::access_handler
        PerlAuthenHandler Apache2::Authn::Redmine::authen_handler
    
        ## for mysql
        RedmineDSN \"DBI:mysql:database=$DB_NAME;host=localhost\"
        RedmineDbUser \"$DB_USERNAME\"
        RedmineDbPass \"$DB_PASSWORD\"
        RedmineGitSmartHttp yes
    </Location>
    
    <Location /sys>
        Order deny,allow
        Allow from 127.0.1.1
        #Allow from localhost
        Deny from all
    </Location>
    
    AddOutputFilter DEFLATE text/html text/plain text/xml application/xml application/xhtml+xml text/javascript text/css
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    
    
    ErrorLog ${APACHE_LOG_DIR}/redmine.error.log
    LogLevel warn
    CustomLog ${APACHE_LOG_DIR}/redmine.access.log combined
    ServerSignature Off
    
</VirtualHost>" > /etc/apache2/sites-available/redmine.vhost


echo -n "# Redirection of port 80 to port 443
<virtualhost *:80>
    ServerName $REDMINE_DOMAIN
  
    KeepAlive Off
  
    RewriteEngine On 
    #RewriteCond %{HTTP_HOST} ^[^\./]+\.[^\./]+$ 
    RewriteRule ^/(.*)$ https://%{HTTP_HOST}/$1 [R=301,L]
  
    <IfModule mod_header.c>
        ## Enable Strict Transport: http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
        Header add Strict-Transport-Security \"max-age=15768000\"
    </IfModule>
  
</virtualhost>" > /etc/apache2/sites-available/redmine-redirect.vhost



#--------------------------------------------
#   Enable


#a2dissite default
a2ensite redmine.vhost
a2ensite redmine-redirect.vhost
service apache2 restart


