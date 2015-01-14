#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Fail2Ban install (LEMP)
#
#   Tested in :
#   Ubuntu 14.04 LTS "trusty"
#
#   Sources :
#   https://www.digitalocean.com/community/tutorials/how-to-install-and-use-fail2ban-on-ubuntu-14-04
#   http://snippets.aktagon.com/snippets/554-how-to-secure-an-nginx-server-with-fail2ban
#   http://serverfault.com/questions/395231/secure-iptables-config-for-samba
#

#  (Ubuntu : as root)
#sudo su

apt-get update
apt-get install fail2ban -y

#       Main config file : use local copy
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

#       Adjust some defaults
sed -e 's,bantime  = 600,bantime  = 1800,g' -i /etc/fail2ban/jail.local
#sed -e 's,destemail = root@localhost,destemail = example@email.com,g' -i /etc/fail2ban/jail.local
sed -e 's,action = %(action_)s,action = %(action_mwl)s,g' -i /etc/fail2ban/jail.local



#----------------------------------------------------------------------------------------------------------------------------------------
#       Basic IPTABLES


iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -j DROP

#       Samba (local dev)
#       @see http://serverfault.com/questions/395231/secure-iptables-config-for-samba
#       -> failed test 2015/01/14 20:54:27
#iptables -A INPUT -i eth0 -s 192.168.0.0/24 -p udp --dport 137:138 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o eth0 -d 192.168.0.0/24 -p udp --sport 137:138 -m state --state ESTABLISHED -j ACCEPT
#iptables -A INPUT -i eth0 -s 192.168.0.0/24 -p tcp --dport 139 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o eth0 -d 192.168.0.0/24 -p tcp --sport 139 -m state --state ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o eth0 -d 192.168.0.0/24 -p tcp --sport 139 -m state --state ESTABLISHED -j ACCEPT


#----------------------------------------------------------------------------------------------------------------------------------------
#       Custom Ngnix conf
#       @see http://snippets.aktagon.com/snippets/554-how-to-secure-an-nginx-server-with-fail2ban


echo '

#       For NginX
#       @see http://snippets.aktagon.com/snippets/554-how-to-secure-an-nginx-server-with-fail2ban

[nginx-auth]
enabled = true
filter = nginx-auth
action = iptables-multiport[name=NoAuthFailures, port="http,https"]
logpath = /var/log/nginx*/*error*.log
bantime = 600
maxretry = 6

[nginx-login]
enabled = true
filter = nginx-login
action = iptables-multiport[name=NoLoginFailures, port="http,https"]
logpath = /var/log/nginx*/*access*.log
bantime = 600
maxretry = 6
 
[nginx-badbots]
enabled  = true
filter = apache-badbots
action = iptables-multiport[name=BadBots, port="http,https"]
logpath = /var/log/nginx*/*access*.log
bantime = 86400
maxretry = 1
 
[nginx-noscript]
enabled = true
action = iptables-multiport[name=NoScript, port="http,https"]
filter = nginx-noscript
logpath = /var/log/nginx*/*access*.log
maxretry = 6
bantime  = 86400
 
[nginx-proxy]
enabled = true
action = iptables-multiport[name=NoProxy, port="http,https"]
filter = nginx-proxy
logpath = /var/log/nginx*/*access*.log
maxretry = 0
bantime  = 86400
' >> /etc/fail2ban/jail.local


#       Filter config
#       @see http://snippets.aktagon.com/snippets/554-how-to-secure-an-nginx-server-with-fail2ban
echo '# Proxy filter /etc/fail2ban/filter.d/nginx-proxy.conf:
#
# Block IPs trying to use server as proxy.
#
# Matches e.g.
# 192.168.1.1 - - "GET http://www.something.com/
#
[Definition]
failregex = ^<HOST> -.*GET http.*
ignoreregex =' > /etc/fail2ban/filter.d/nginx-proxy.conf


echo '# Noscript filter /etc/fail2ban/filter.d/nginx-noscript.conf:
#
# Block IPs trying to execute scripts such as .php, .pl, .exe and other funny scripts.
#
# Matches e.g.
# 192.168.1.1 - - "GET /something.php
#
[Definition]
failregex = ^<HOST> -.*GET.*(\.php|\.asp|\.exe|\.pl|\.cgi|\scgi)
ignoreregex =' > /etc/fail2ban/filter.d/nginx-noscript.conf


echo '# Auth filter /etc/fail2ban/filter.d/nginx-auth.conf:
#
# Blocks IPs that fail to authenticate using basic authentication
#
[Definition]
 
failregex = no user/password was provided for basic authentication.*client: <HOST>
            user .* was not found in.*client: <HOST>
            user .* password mismatch.*client: <HOST>
 
ignoreregex =' > /etc/fail2ban/filter.d/nginx-auth.conf


echo '# Login filter /etc/fail2ban/filter.d/nginx-login.conf:
#
# Blocks IPs that fail to authenticate using web application log in page
#
# Scan access log for HTTP 200 + POST /sessions => failed log in
[Definition]
failregex = ^<HOST> -.*POST /sessions HTTP/1\.." 200
ignoreregex =' > /etc/fail2ban/filter.d/nginx-login.conf



#----------------------------------------------------------------------------------------------------------------------------------------
#       Restart Fail2ban Service


service fail2ban stop
service fail2ban start


