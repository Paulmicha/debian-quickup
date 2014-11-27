#!/bin/bash
# -*- coding: UTF8 -*-

##
#   PostGreSQL debian installation
#   
#   Tested on debian 7 (Wheezy)
#   @timestamp 2013/09/18 15:26:45
#   
#   Sources :
#   @see http://bailey.st/blog/2013/05/14/how-to-install-postgresql-9-2-on-debian-7-wheezy/
#   @see http://www.postgresql.org/download/linux/debian/
#   @see http://stackoverflow.com/questions/10757431/postgres-upgrade-a-user-to-be-a-superuser
#   

#       If you use this (as of 2013/09/18 15:29:12) you will get 9.1
#aptitude install postgresql -y

#       As of 2013/09/18 15:31:53, this will install postgresql version 9.3
#       @see http://bailey.st/blog/2013/05/14/how-to-install-postgresql-9-2-on-debian-7-wheezy/
aptitude install python-software-properties -y
wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main"
apt-get update
apt-get install postgresql -y

#       Then install php support
apt-get install php5-pgsql -y
service apache2 restart



#----------------------------------------
#       Setup first user
#       @todo 2012/12/07 17:05:11 - rewrite those for inline execution

su - postgres
psql
    CREATE USER mypguser WITH PASSWORD 'mypguserpass';
    \q



#----------------------------------------
#       Make any user a superuser
#       @see http://stackoverflow.com/questions/10757431/postgres-upgrade-a-user-to-be-a-superuser

psql
    ALTER USER mypguser WITH SUPERUSER;
    \q



#----------------------------------------
#       Setup first database

psql
    CREATE DATABASE mypgdatabase;
    GRANT ALL PRIVILEGES ON DATABASE mypgdatabase to mypguser;
    \q



#----------------------------------------
#       Install PhpPgAdmin
#       @see http://phppgadmin.sourceforge.net/doku.php?id=download

#       Edit conf/config.inc.php,
#           replace :
$conf['servers'][0]['host'] = '';
#           with :
$conf['servers'][0]['host'] = 'localhost';



#----------------------------------------
#       Snippets

#       Import DB dump
pg_restore --username "mypguser" --dbname "mypgdatabase" -h localhost --verbose --ignore-version /path/to/file/mypgdatabase_dump.sql.tar

#       Create DB dump
pg_dump -U mypguser -h localhost -F t mypgdatabase > mypgdatabase_dump.sql.tar


