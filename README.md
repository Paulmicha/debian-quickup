LAMP server quick setup shell script
====================================

For local dev.
Drupal & Symfony friendly.
Tested on Debian 6 "Squeeze".

Prerequisites : A freshly installed Debian Linux server (or Ubuntu - untested), su or root session.
Usage : copy & customize & paste the following shell command lines, or customize altogether to your liking.
First param is optional - when not set, the defaut MySQL root user password will be "changeThisPassword"

Php 5.3 :
<pre>wget "https://raw.github.com/Paulmicha/debian-quickup/master/lamp_setup.sh" --quiet --no-check-certificate
chmod +x "lamp_setup.sh"
./lamp_setup.sh this_first_param_is_the_mysql_root_password</pre>

Php 5.4 :
<pre>wget "https://raw.github.com/Paulmicha/debian-quickup/master/lamp_setup_php54.sh" --quiet --no-check-certificate
chmod +x "lamp_setup_php54.sh"
./lamp_setup_php54.sh this_first_param_is_the_mysql_root_password</pre>
