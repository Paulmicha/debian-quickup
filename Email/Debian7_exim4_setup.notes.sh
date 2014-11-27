#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Exim 4 installation (with anti spam & antivirus)
#   
#   Prereq :
#   antivirus_clamav.sh (ClamAV antivirus installation)
#   
#   Tested in :
#   Debian 7 "wheezy"
#   Ubuntu 14.04 LTS "trusty"
#
#   Sources :
#   http://howto.biapy.com/fr/debian-gnu-linux/serveurs/e-mails/configurer-exim-4-sur-debian
#

#  (as root)
sudo su

NEW_FQDN="smtp.domain.com"
SSL_KEY_NAME="${NEW_FQDN}"

apt-get install exim4-daemon-heavy -y

#       Use Exim split config
sed -i \
    -e 's/^\(dc_use_split_config=\).*/\1'true'/' \
    '/etc/exim4/update-exim4.conf.conf'

update-exim4.conf
adduser Debian-exim ssl-cert

#       Certificate path
SMTP_SSL_KEY="/etc/ssl/private/${SSL_KEY_NAME}.key"
if [ -e "/etc/ssl/certificates/${SSL_KEY_NAME}.crt+chain+root" ]; then
    SMTP_SSL_CRT="/etc/ssl/certificates/${SSL_KEY_NAME}.crt+chain+root"
else
    SMTP_SSL_CRT="/etc/ssl/certificates/${SSL_KEY_NAME}.crt"
fi

#       TLS
if [ -e "${SMTP_SSL_KEY}" -a -e "${SMTP_SSL_CRT}" ]; then
    echo "
### main/02_exim4-config_tlscert
#################################

# ENABLING TLS
MAIN_TLS_ENABLE = true

# SSL private key
MAIN_TLS_PRIVATEKEY = ${SMTP_SSL_KEY}

# SSL public key
MAIN_TLS_CERTIFICATE = ${SMTP_SSL_CRT}

# Disabling certificate verification to avoid problems with some
# mail clients when using CACert (or self signed) certificates.
# Concerned mail clients : Outlook 2003, Mail for Mac OS X...
MAIN_TLS_VERIFY_CERTIFICATES = /dev/null
" > '/etc/exim4/conf.d/main/02_exim4-config_tlscert'
fi

#       Restart to reload configuration
/etc/init.d/exim4 restart



#----------------------------------------------------------------------------------------
#       Anti-spam Protection


#       Get HELO filter rules
wget 'https://raw.github.com/biapy/howto.biapy.com/master/exim4/exim4_helo_checks.conf' \
    --quiet --no-check-certificate --output-document='/tmp/exim4_helo_checks.conf'
sed -i \
    -e '/hosts[ \t]*=[ \t]*:/r /tmp/exim4_helo_checks.conf' \
    '/etc/exim4/conf.d/acl/30_exim4-config_check_rcpt'

#       Cleanup
rm '/tmp/exim4_helo_checks.conf'

#       Init list of IPs & hosts considered incorrect HELOs :
echo "127.0.0.1
localhost
localhost.localdomain" \
    > '/etc/exim4/rejected-helo.conf'

#       Reload config
/etc/init.d/exim4 reload


#       SpamAssassin
apt-get install spamassassin sa-exim re2c make gcc libc6-dev -y
sed -i \
    -e 's/^ENABLED=.*/ENABLED=1/' \
    -e 's/^CRON=.*/CRON=1/' \
    '/etc/default/spamassassin'

#       Update filters (minutes long)
/etc/cron.daily/spamassassin

#       SpamAssassin is resource-hungry
#       -> a few safe exclusion filters to "lighten" it up a bit
wget 'https://raw.github.com/biapy/howto.biapy.com/master/exim4/exim4_no_spam_scan_acl.conf' \
    --quiet --no-check-certificate --output-document='/tmp/exim4_no_spam_scan_acl.conf'
sed -i \
    -e '/hosts[ \t]*=[ \t]*:/r /tmp/exim4_no_spam_scan_acl.conf' \
    '/etc/exim4/conf.d/acl/30_exim4-config_check_rcpt'
rm '/tmp/exim4_no_spam_scan_acl.conf'

#       Activate SA-Exim
#       + config it to check e-mails non-marked by Exim server
sed -i -e 's/^SAEximRunCond: [01]/SAEximRunCond: ${if !eq{$acl_m0}{do-not-scan}}/' \
    -e '/SAEximRejCond:/a\
SAEximRejCond: ${if !eq{$acl_m0}{do-not-reject}}' \
    '/etc/exim4/sa-exim.conf'

#       Reload config
/etc/init.d/exim4 reload

#       NB : Ajustez le seuil de rejet des Spam dans le fichier /etc/exim4/sa-exim.conf en modifiant la valeur:
#SApermreject: 12.0



#----------------------------------------------------------------------------------------
#       Anti-virus Protection


apt-get install clamav-daemon \
    daemon unrar arj debconf-utils unzip unace \
    cpio zoo nomarch lzop cabextract pax -y

adduser clamav Debian-exim
su - -c "/etc/init.d/clamav-daemon restart"

#       Configure Exim 4 to use the antivirus
sed -i \
    -e 's|^.*av_scanner[ \t]*=.*$|av_scanner = clamd:/var/run/clamav/clamd.ctl|' \
    '/etc/exim4/conf.d/main/02_exim4-config_options'

#       Reject infected emails
echo '
# local-acl.conf
###################"

# This file is included in acl/40_exim4-config_check_data
# using the CHECK_DATA_LOCAL_ACL_FILE macro.

  # Deny viruses.
  deny
    message = Message contains malware or a virus ($malware_name).
    log_message = $sender_host_address tried sending $malware_name
    demime = *
    malware = *
' >> '/etc/exim4/local-acl.conf'

#       Create macro CHECK_DATA_LOCAL_ACL_FILE
echo "
### main/01_exim4-local_acl_macrodefs
#################################

.ifndef CHECK_DATA_LOCAL_ACL_FILE
CHECK_DATA_LOCAL_ACL_FILE = /etc/exim4/local-acl.conf
.endif
" > '/etc/exim4/conf.d/main/01_exim4-local_acl_macrodefs'

#       Reload SMTP config
/etc/init.d/exim4 restart


#       NB : Le projet eicar (The antivirus or malwhare test file)
#       fournit des fichiers tests générant des faux positifs.
#       La configuration est fonctionnelle si les emails contenant un de ces fichiers sont rejetés.
#       @see http://www.eicar.org/anti_virus_test_file.htm



#----------------------------------------------------------------------------------------
#       Augment number of outgoing emails per connection


echo "
### main/04_exim4-config_queueoptions
#################################

# Allow up to 100 messages by connexion.
# Avoid the apparition of 'no immediate delivery: more than 10 messages received in one connection' warning.
smtp_accept_queue_per_connection = 100
" > '/etc/exim4/conf.d/main/04_exim4-config_queueoptions'

/etc/init.d/exim4 reload


