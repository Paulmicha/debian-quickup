#!/bin/bash
# -*- coding: UTF8 -*-

##
#   XHProf setup
#   Debian 6 ("Squeeze")
#
#   Sources :
#   http://techportal.inviqa.com/2009/12/01/profiling-with-xhprof/
#   https://github.com/facebook/xhprof
#
#   @datestamp 2012/12/14 15:42:30
#

#       Prerequisites (skip if already installed)
#       Packages "make", "php5-dev"
apt-get install php5-dev make -y

#       Install with Pear IF your server is running PHP <= 5.2 (check command : "php -v")
#       Otherwise, see below
#       @see http://pecl.php.net/package/xhprof
pecl config-set preferred_state beta
pecl install xhprof -y

#       When you get the following error, it probably means you're using php > 5.2 :
#running: make
#/bin/bash /tmp/pear/temp/pear-build-rootxASPcX/xhprof-0.9.2/libtool --mode=compile cc  -I. -I/tmp/pear/temp/xhprof/extension -DPHP_ATOM_INC -I/tmp/pear/temp/pear-build-rootxASPcX/xhprof-0.9.2/include -I/tmp/pear/temp/pear-build-rootxASPcX/xhprof-0.9.2/main -I/tmp/pear/temp/xhprof/extension -I/usr/include/php5 -I/usr/include/php5/main -I/usr/include/php5/TSRM -I/usr/include/php5/Zend -I/usr/include/php5/ext -I/usr/include/php5/ext/date/lib -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64  -DHAVE_CONFIG_H  -g -O2   -c /tmp/pear/temp/xhprof/extension/xhprof.c -o xhprof.lo
#libtool: compile:  cc -I. -I/tmp/pear/temp/xhprof/extension -DPHP_ATOM_INC -I/tmp/pear/temp/pear-build-rootxASPcX/xhprof-0.9.2/include -I/tmp/pear/temp/pear-build-rootxASPcX/xhprof-0.9.2/main -I/tmp/pear/temp/xhprof/extension -I/usr/include/php5 -I/usr/include/php5/main -I/usr/include/php5/TSRM -I/usr/include/php5/Zend -I/usr/include/php5/ext -I/usr/include/php5/ext/date/lib -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DHAVE_CONFIG_H -g -O2 -c /tmp/pear/temp/xhprof/extension/xhprof.c  -fPIC -DPIC -o .libs/xhprof.o
#/tmp/pear/temp/xhprof/extension/xhprof.c:236: warning: ‘visibility’ attribute ignored
#/tmp/pear/temp/xhprof/extension/xhprof.c:240: warning: ‘visibility’ attribute ignored
#/tmp/pear/temp/xhprof/extension/xhprof.c: In function ‘hp_get_function_name’:
#/tmp/pear/temp/xhprof/extension/xhprof.c:898: warning: assignment discards qualifiers from pointer target type
#/tmp/pear/temp/xhprof/extension/xhprof.c:909: warning: assignment discards qualifiers from pointer target type
#/tmp/pear/temp/xhprof/extension/xhprof.c:911: warning: assignment discards qualifiers from pointer target type
#/tmp/pear/temp/xhprof/extension/xhprof.c:930: error: ‘znode_op’ has no member named ‘u’
#/tmp/pear/temp/xhprof/extension/xhprof.c:963: warning: passing argument 1 of ‘hp_get_base_filename’ discards qualifiers from pointer target type
#/tmp/pear/temp/xhprof/extension/xhprof.c:856: note: expected ‘char *’ but argument is of type ‘const char *’
#/tmp/pear/temp/xhprof/extension/xhprof.c: In function ‘hp_execute_internal’:
#/tmp/pear/temp/xhprof/extension/xhprof.c:1650: error: ‘znode_op’ has no member named ‘u’
#/tmp/pear/temp/xhprof/extension/xhprof.c:1651: error: ‘struct <anonymous>’ has no member named ‘return_reference’
#/tmp/pear/temp/xhprof/extension/xhprof.c:1652: error: ‘znode_op’ has no member named ‘u’
#/tmp/pear/temp/xhprof/extension/xhprof.c: In function ‘hp_compile_file’:
#/tmp/pear/temp/xhprof/extension/xhprof.c:1683: warning: passing argument 1 of ‘hp_get_base_filename’ discards qualifiers from pointer target type
#/tmp/pear/temp/xhprof/extension/xhprof.c:856: note: expected ‘char *’ but argument is of type ‘const char *’
#make: *** [xhprof.lo] Erreur 1
#ERROR: `make' failed


#       Need to get the latest version and compile
#       @see https://github.com/facebook/xhprof
#       NB : use the dir you want, it will contain the lib
mkdir /usr/local/lib/php
cd /usr/local/lib/php
git clone https://github.com/facebook/xhprof.git
cd xhprof/extension
phpize
./configure --with-php-config=/usr/bin/php-config
make
make install
make test

#       Add xhprof.so extension, then restart apache (and check that the module is loaded using : php -m)
echo -e "extension=xhprof.so
xhprof.output_dir=\"/var/tmp/xhprof\"" > /etc/php5/apache2/conf.d/xhprof.ini
service apache2 restart

#       Install graphviz
apt-get install graphviz -y



#------------------------------------------------------------------------------------------------------------------------
#       XHProf UI
#       The code for the XHProf UI can be found in the xhprof_html/ and xhprof_lib/ directories.
#       Assuming they are created in /usr/local/lib/php/, we can symlink that directory to /var/www/xhprof/ so it's available from our DocumentRoot.

#       @todo 2012/12/14 16:47:04



