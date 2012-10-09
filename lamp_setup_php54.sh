#!/bin/bash
# -*- coding: UTF8 -*-

##
#   LAMP server quick setup shell script, for local dev purposes (run as su or root),
#   tested on Debian 6 "Squeeze", Drupal & Symfony friendly
#
#   Credits : Some bits learned from the excellent explanations at http://howto.biapy.com/
#   @author Paulmicha
#

VERSION="1.0-dev"
SCRIPT_NAME="$(basename ${0})"


##
#   Usage info
#
function usage {
  echo "Debian quickup v${VERSION}
Drupal & Symfony friendly LAMP (Php 5.4 from DotDeb) server quick setup shell script for local dev
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
#       Using DotDeb sources for Php-5.4

#       Adding "dotdeb" packages in sources
cp /etc/apt/sources.list /etc/apt/sources.list.bak
echo "deb http://packages.dotdeb.org squeeze all
deb-src http://packages.dotdeb.org squeeze all
deb http://packages.dotdeb.org squeeze-php54 all
deb-src http://packages.dotdeb.org squeeze-php54 all" >> /etc/apt/sources.list

#       GnuPG Key to access dotdeb packets
wget http://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
rm dotdeb.gpg

#       Then update
apt-get update
apt-get upgrade



#----------------------------------------------------------------------------
#       LAMP stack

#       Apache
apt-get install apache2-mpm-worker -y
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
mysqladmin -u root password "${MYSQL_ADMIN_PASSWORD}"

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
apt-get install php5 php5-dev php5-cli php5-common php5-mysql php5-curl php-pear php5-gd php5-mcrypt php5-xdebug -y
apt-get install php5-imagick -y
apt-get install php5-intl -y
pecl install uploadprogress
echo -e "extension=uploadprogress.so" > /etc/php5/apache2/conf.d/uploadprogress.ini

#       APC
if [ -n "$(apt-cache pkgnames php5-apc)" \
    -a -n "$(dpkg --status "php5-common" | grep "dotdeb")" ]; then
  # Check for dot-deb packages.
  apt-get -y install php5-apc
elif [ -n "$(apt-cache pkgnames php-apc)" ]; then
  apt-get -y install php-apc
fi

#       UTF-8 for mbstring
echo '; Set mbstring defaults to UTF-8
mbstring.language=UTF-8
mbstring.internal_encoding=UTF-8
; mbstring.http_input=UTF-8
; mbstring.http_output=UTF-8
mbstring.detect_order=auto' \
    > '/etc/php5/conf.d/mbstring.ini'

#       XDebug : enable remote debug
echo '; Enable Remote XDebug
xdebug.remote_enable=on
xdebug.remote_handler=dbgp
xdebug.remote_host=0.0.0.0
xdebug.remote_port=9000' \
    > '/etc/php5/conf.d/xdebug.ini'

#       Main php.ini configuration
mv /etc/php5/apache2/php.ini /etc/php5/apache2/php.ini.bak
echo -n "engine = On
short_open_tag = Off
asp_tags = Off
precision = 14
y2k_compliance = On
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 100
allow_call_time_pass_reference = Off
safe_mode = Off
safe_mode_gid = Off
safe_mode_include_dir =
safe_mode_exec_dir =
safe_mode_allowed_env_vars = PHP_
safe_mode_protected_env_vars = LD_LIBRARY_PATH
disable_functions =
disable_classes =
expose_php = On
max_execution_time = 120
max_input_time = 160
memory_limit = 256M
error_reporting = E_ALL & ~E_DEPRECATED
display_errors = On
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On
variables_order = \"GPCS\"
request_order = \"GP\"
register_globals = Off
register_long_arrays = Off
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 130M
magic_quotes_gpc = Off
magic_quotes_runtime = Off
magic_quotes_sybase = Off
auto_prepend_file =
auto_append_file =
default_mimetype = \"text/html\"
default_charset = \"utf-8\"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 120M
max_file_uploads = 99
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
date.timezone = \"$(command cat /etc/timezone)\"
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=
define_syslog_variables  = Off
SMTP = localhost
smtp_port = 25
mail.add_x_header = On
sql.safe_mode = Off
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = \"%Y-%m-%d %H:%M:%S\"
ibase.dateformat = \"%Y-%m-%d\"
ibase.timeformat = \"%H:%M:%S\"
mysql.allow_local_infile = On
mysql.allow_persistent = On
mysql.cache_size = 2000
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10
bcmath.scale = 0
session.autostart = Off
session.save_handler = files
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 0
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.bug_compat_42 = Off
session.bug_compat_warn = Off
session.referer_check =
session.entropy_length = 0
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = \"a=href,area=href,frame=src,input=src,form=fakeentry\"
mssql.allow_persistent = On
mssql.max_persistent = -1
mssql.max_links = -1
mssql.min_error_severity = 10
mssql.min_message_severity = 10
mssql.compatability_mode = Off
mssql.secure_connection = Off
tidy.clean_output = Off
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir=\"/tmp\"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
ldap.max_links = -1" > /etc/php5/apache2/php.ini
#/etc/init.d/apache2 restart

#       Composer
cp /etc/php5/conf.d/suhosin.ini /etc/php5/conf.d/suhosin.ini.bak
echo "suhosin.executor.include.whitelist = phar" >> /etc/php5/conf.d/suhosin.ini
#/etc/init.d/apache2 restart
curl -s http://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#       SQLite3
apt-get install sqlite3
apt-get install php5-sqlite

#       Restart
/etc/init.d/apache2 restart



#----------------------------------------------------------------------------
#       Server tools

#       Utils
apt-get install unzip -y
apt-get install htop -y

#       Time sync
apt-get install ntp ntpdate -y
ntpdate fr.pool.ntp.org

#       Versionning
apt-get install subversion -y
apt-get install git-core -y

#       Drush
pear upgrade-all
pear channel-discover pear.drush.org
pear install drush/drush


