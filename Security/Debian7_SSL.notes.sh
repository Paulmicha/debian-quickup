#!/bin/bash
# -*- coding: UTF8 -*-

##
#   SSL certificate installation
#
#   Tested in :
#   Debian 7 "wheezy"
#   Ubuntu 14.04 LTS "trusty"
#
#   Sources :
#   http://howto.biapy.com/fr/debian-gnu-linux/serveurs/http/creer-un-certificat-ssl-sur-debian
#

#  (Ubuntu : as root)
sudo su

apt-get install openssl ssl-cert -y

mkdir --parent '/etc/ssl/private'
mkdir --parent '/etc/ssl/requests'
mkdir --parent '/etc/ssl/roots'
mkdir --parent '/etc/ssl/chains'
mkdir --parent '/etc/ssl/certificates'
mkdir --parent '/etc/ssl/authorities'
mkdir --parent '/etc/ssl/configs'

#       addgroup: The group `ssl-cert' already exists as a system group. Exiting.
#       -> optional
#addgroup --system 'ssl-cert'

chown -R root:ssl-cert '/etc/ssl/private'
chmod 710 '/etc/ssl/private'
chmod 440 '/etc/ssl/private/'*



#-------------------------------------------------------------------------------------------------------------
#       Option 1 : Auto-signed (LAN)


SSL_KEY_NAME="$(hostname --fqdn)"
CONF_FILE="$(mktemp)"
sed -e "s/@HostName@/${SSL_KEY_NAME}/" \
    -e "s|privkey.pem|/etc/ssl/private/${SSL_KEY_NAME}.key|" \
    '/usr/share/ssl-cert/ssleay.cnf' > "${CONF_FILE}"
openssl req -config "${CONF_FILE}" -new -x509 -days 3650 \
    -nodes -out "/etc/ssl/certificates/${SSL_KEY_NAME}.crt" -keyout "/etc/ssl/private/${SSL_KEY_NAME}.key"
rm "${CONF_FILE}"

chown root:ssl-cert "/etc/ssl/private/${SSL_KEY_NAME}.key"
chmod 440 "/etc/ssl/private/${SSL_KEY_NAME}.key"

#       NB : Debian fourni un outil pour créer des certificats auto-signés,
#       mais il ne permet pas de séparer la clef privée de la clef publique :
# make-ssl-cert '/usr/share/ssl-cert/ssleay.cnf' '/etc/ssl/certificates/${SSL_KEY_NAME}.crt'



#-------------------------------------------------------------------------------------------------------------
#       Option 2 : StartSSL (internet)


#       StartSSL free plan does not support wildcards (*)
#       -> repeat per domain AND sub-domain
SSL_KEY_NAME="www.domain.com"

#       Need some info to generate PRIVATE key
#       -> test if we already have generated it
if [ -e '/etc/ssl/csr-informations' ]; then
    source '/etc/ssl/csr-informations'
    cat '/etc/ssl/csr-informations'
else
    #       First time
    #       -> generate content
    SSL_COUNTRY="fr"
    SSL_PROVINCE="Ile-de-France"
    SSL_CITY="Paris"
    SSL_EMAIL="user@some-domain.com"
    echo "# SSL CSR informations.
SSL_COUNTRY=\"${SSL_COUNTRY}\"
SSL_PROVINCE=\"${SSL_PROVINCE}\"
SSL_CITY=\"${SSL_CITY}\"
SSL_EMAIL=\"${SSL_EMAIL}\"" \
        > '/etc/ssl/csr-informations'
fi

openssl genrsa -out "/etc/ssl/private/${SSL_KEY_NAME}.key" 2048

chown root:ssl-cert "/etc/ssl/private/${SSL_KEY_NAME}.key"
chmod 440 "/etc/ssl/private/${SSL_KEY_NAME}.key"

openssl req -new \
    -key "/etc/ssl/private/${SSL_KEY_NAME}.key" \
    -out "/etc/ssl/requests/${SSL_KEY_NAME}.csr" \
    <<< "${SSL_COUNTRY}
${SSL_PROVINCE}
${SSL_CITY}
${SSL_KEY_NAME}

${SSL_KEY_NAME}
${SSL_EMAIL}

"

#       Now, for the PUBLIC key :
#       go to "Certificate Wizard" on StartSSL
#       you'll need this CSR :
cat "/etc/ssl/requests/${SSL_KEY_NAME}.csr"

#       Once you have your public key, copy/paste it in this var :
SSL_CERT="-----BEGIN CERTIFICATE-----
MIIHJzCCBg+gAwIBAgIDBNzOMXAXCDRTSIKDOWQBBQUAAGEOMMQscZfGLDVQQGEwJJ
 .... .... .....
H5LYbXPAq3DpOzs=
-----END CERTIFICATE-----"

#       Carry on
echo "${SSL_CERT}" > "/etc/ssl/certificates/${SSL_KEY_NAME}.crt"

wget "http://www.startssl.com/certs/ca.pem" \
        --output-document="/etc/ssl/roots/startssl-root.ca"
wget "http://www.startssl.com/certs/sub.class1.server.ca.pem" \
        --output-document="/etc/ssl/chains/startssl-sub.class1.server.ca.pem"
wget "http://www.startssl.com/certs/sub.class2.server.ca.pem" \
        --output-document="/etc/ssl/chains/startssl-sub.class2.server.ca.pem"
wget "http://www.startssl.com/certs/sub.class3.server.ca.pem" \
        --output-document="/etc/ssl/chains/startssl-sub.class3.server.ca.pem"

ln -s "/etc/ssl/roots/startssl-root.ca" "/etc/ssl/roots/${SSL_KEY_NAME}-root.ca"

if [ "${SSL_KEY_NAME}" = "$(echo "${SSL_KEY_NAME}" | tr '*' '.')" ]; then
    ln -s "/etc/ssl/chains/startssl-sub.class1.server.ca.pem" "/etc/ssl/chains/${SSL_KEY_NAME}.ca"
else
    ln -s "/etc/ssl/chains/startssl-sub.class2.server.ca.pem" "/etc/ssl/chains/${SSL_KEY_NAME}.ca"
fi

cp "/etc/ssl/certificates/${SSL_KEY_NAME}.crt" "/etc/ssl/certificates/${SSL_KEY_NAME}.crt+chain+root"
test -e "/etc/ssl/chains/${SSL_KEY_NAME}.ca" \
    && cat "/etc/ssl/chains/${SSL_KEY_NAME}.ca" >> "/etc/ssl/certificates/${SSL_KEY_NAME}.crt+chain+root"
test -e "/etc/ssl/roots/${SSL_KEY_NAME}-root.ca" \
    && cat "/etc/ssl/roots/${SSL_KEY_NAME}-root.ca" >> "/etc/ssl/certificates/${SSL_KEY_NAME}.crt+chain+root"


